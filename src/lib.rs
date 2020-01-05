#[macro_use]
extern crate diesel;

use actix_files::{NamedFile, Files};
use actix_web::{
    HttpResponse, Resource, Result,
    web, guard, error, http::StatusCode,
    dev::ServiceRequest
};

use handlebars::Handlebars;
use serde::Deserialize;
use serde_json::json;
use std::{env, fmt};

pub mod db;
pub mod models;
pub mod schema;
pub mod templates { pub mod registry; }
pub mod require_https;

pub use require_https::RequireHttps;

#[derive(fmt::Debug)]
pub struct ApplicationState<'a> {
    pub template_registry: Handlebars<'a>,
}

#[derive(fmt::Debug)]
pub struct ApplicationError<'a> {
    data: web::Data<ApplicationState<'a>>
}

impl fmt::Display for ApplicationError<'_> {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        let context = json!({
            "currentPage": "500",
            "title": "Internal Server Error",
        });
        let body = self.data.template_registry.render("500", &context).unwrap_or("Internal Server Error".to_string());
        write!(f, "{}", body)
    }
}

impl error::ResponseError for ApplicationError<'_> {
    fn status_code(&self) -> StatusCode {
        StatusCode::INTERNAL_SERVER_ERROR
    }

    fn error_response(&self) -> HttpResponse {
        HttpResponse::build(self.status_code())
            .content_type("text/html; charset=utf-8")
            .body(self.to_string())
    }
}

#[derive(Deserialize)]
pub struct MessagePayload {
    pub message_group: String,
    pub index: i32,
    pub body: String,
    pub author: String,
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.data(app_state())
        .service(static_files())
        .route("/favicon.ico", web::get().to(favicon))
        .route("/", web::get().to(home))
        .route("/about", web::get().to(about))
        .route("/error", web::get().to(test_error))
        .route("/messages/{message_group}", web::get().to(load_message_group))
        .route("/messages/{message_group}", web::post().to(create_message_in_group));
}

pub fn default_service() -> Resource {
    // 404 for GET request
    web::resource("")
        .route(web::get().to(p404))
        // all requests that are not `GET`
        .route(
            web::route()
                .guard(guard::Not(guard::Get()))
                .to(HttpResponse::MethodNotAllowed),
        )
}

pub fn app_state<'a>() -> ApplicationState<'a> {
    ApplicationState {
        template_registry: register_templates(),
    }
}

pub fn error_body(req: &ServiceRequest) -> String {
    let default = "Internal Server Error".to_string();
    let web_data : std::option::Option<actix_web::web::Data<ApplicationState>>  = req.app_data();
    if let Some(web_data) = web_data {
        let context = json!({
            "status": "500",
            "title": "Internal Server Error"
        });
        web_data.template_registry.render("500", &context).unwrap_or(default)
    } else {
        default
    }
}

pub fn error_json() -> serde_json::Value {
    json!({
        "error": {
            "status": "500",
            "title": "Internal Server Error",
        }
    })
}

pub fn not_found_json() -> serde_json::Value {
    json!({
        "error": {
            "status": "404",
            "title": "Not Found",
        }
    })
}

pub fn p404(data: web::Data<ApplicationState<'_>>) -> HttpResponse {
    let context = json!({
        "currentPage": "404",
        "title": "Not Found",
    });

    let body = data.template_registry.render("404", &context).unwrap_or("Not Found".to_string());
    HttpResponse::NotFound()
        .content_type("text/html; charset=utf-8")
        .body(body)
}

pub async fn favicon() -> Result<NamedFile> {
    Ok(NamedFile::open("static/favicon.ico")?)
}

pub async fn test_error(data: web::Data<ApplicationState<'_>>) -> Result<&'_ str, ApplicationError<'_>> {
    Err(ApplicationError { data: data })
}

pub fn static_files() -> Files {
    Files::new("/static", "static").show_files_listing()
}

pub async fn home(data: web::Data<ApplicationState<'_>>) -> Result<HttpResponse, ApplicationError<'_>> {
    let context = json!({
        "currentPage": "home",
        "title": "Home",
    });

    render_html(data, StatusCode::OK, "home", context)
}

pub fn render_html<'a>(data: web::Data<ApplicationState<'a>>, status_code: StatusCode, template_name: &str, context: serde_json::Value) -> Result<HttpResponse, ApplicationError<'a>> {
    match data.template_registry.render(template_name, &context) {
        Ok(s) => {
            Ok(HttpResponse::build(status_code)
                .content_type("text/html; charset=utf-8")
                .body(s))
        },
        Err(_) => Err(ApplicationError { data })
    }
}

pub async fn about(data: web::Data<ApplicationState<'_>>) -> Result<HttpResponse, ApplicationError<'_>> {
    let context = json!({
        "currentPage": "about",
        "title": "About",
    });

    render_html(data, StatusCode::OK, "about", context)
}

pub fn register_templates<'a>() -> Handlebars<'a> {
    templates::registry::register_templates()
}

pub async fn create_message_in_group<'a>(path: web::Path<String>, mut message_payload: web::Json<MessagePayload>) -> Result<HttpResponse, ApplicationError<'a>> {
    let message_group = &format!("{}", path);
    if !authorized(&message_group) {
        Ok(HttpResponse::NotFound()
            .content_type("application/json; charset=utf-8")
            .json(not_found_json()))
    } else {
        message_payload.message_group = message_group.to_string();
        let message_author_1 = env::var("MESSAGE_AUTHOR_1_ID").unwrap_or("".to_string());
        message_payload.author = message_author_1;

        let key = format!("message{}", message_payload.index);
        let connection = db::establish_connection();
        if db::create_message(&connection, &message_payload).is_ok() {
            Ok(HttpResponse::Created()
                .content_type("application/json; charset=utf-8")
                .json(json!({
                    "currentPage": "messages",
                    "title": "Messages",
                    key: message_payload.body,
                })))
        } else {
            Ok(HttpResponse::InternalServerError()
                .content_type("application/json; charset=utf-8")
                .json(error_json()))
        }
    }
}

pub async fn load_message_group(data: web::Data<ApplicationState<'_>>, path: web::Path<String>) -> Result<HttpResponse, ApplicationError<'_>> {
    let message_group = format!("{}", path);
    if !authorized(&message_group) {
        Ok(p404(data))
    } else {
        let connection = db::establish_connection();
        let query_result = db::message_bodies_for_group(&connection, &message_group);
        let new_messages = if query_result.is_err() {
            return Err(ApplicationError { data });
        } else {
            query_result.unwrap()
        };

        let button_text_1 = button_text(&new_messages[1]);
        let input_disabled_1 = input_disabled(&new_messages[1]);
        let button_text_3 = button_text(&new_messages[3]);
        let input_disabled_3 = input_disabled(&new_messages[3]);
        let guidance_1 = guidance(&new_messages[1]);
        let guidance_3 = guidance(&new_messages[3]);

        let context = json!({
            "currentPage": "messages",
            "title": "Messages",
            "author0": "a0",
            "author1": "a1",
            "message0": paragraphs(&new_messages[0]),
            "message1": &new_messages[1],
            "inputDisabled1": input_disabled_1,
            "buttonText1": button_text_1,
            "guidance1": guidance_1,
            "message2": paragraphs(&new_messages[2]),
            "inputDisabled3": input_disabled_3,
            "buttonText3": button_text_3,
            "guidance3": guidance_3,
            "message3": &new_messages[3],
            "messageGroup": message_group,
        });

        render_html(data, StatusCode::OK, "messages", context)
    }
}

fn paragraphs(body: &str) -> String {
    body.split("\n").map(|paragraph| format!("<p>{}</p>", paragraph)).collect::<Vec<String>>().join("")
}

fn button_text(body: &str) -> &str {
    if body.len() > 0 {
        "Edit"
    } else {
        "Save"
    }
}

fn input_disabled(body: &str) -> &str {
    if body.len() > 0 {
        "disabled"
    } else {
        ""
    }
}

fn guidance(body: &str) -> &str {
    if body.len() > 0 {
        ""
    } else {
        "You will be able to edit after saving."
    }
}

fn authorized(message_group: &str) -> bool {
    let allowed_message_group = env::var("MESSAGE_GROUP_ID").unwrap_or("".to_string());
    message_group == allowed_message_group
}
