#[macro_use]
extern crate log;

#[macro_use]
extern crate diesel;

use actix_files::{NamedFile, Files};
use actix_web::{
    HttpResponse, Responder, Resource, Result,
    web, guard
};

use handlebars::Handlebars;
use serde::Deserialize;
use serde_json::json;
use std::{env};

pub mod db;
pub mod models;
pub mod schema;
pub mod templates { pub mod registry; }
pub mod require_https;

pub use require_https::RequireHttps;

pub struct AppState<'a> {
    pub template_registry: Handlebars<'a>,
}

#[derive(Deserialize)]
pub struct MessagePayload {
    pub message_group: String,
    pub index: i32,
    pub body: String,
    pub author: String,
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.data(request_data())
        .service(static_files())
        .route("/favicon.ico", web::get().to(favicon))
        .route("/", web::get().to(home))
        .route("/about", web::get().to(about))
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

pub fn request_data<'a>() -> AppState<'a> {
    AppState {
        template_registry: register_templates(),
    }
}

pub fn p404(data: web::Data<AppState<'_>>) -> HttpResponse {
    let context = json!({
        "currentPage": "404",
        "title": "Not Found",
    });

    HttpResponse::NotFound()
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("404", &context).unwrap())
}

pub async fn favicon() -> Result<NamedFile> {
    Ok(NamedFile::open("static/favicon.ico")?)
}

pub fn static_files() -> Files {
    Files::new("/static", "static").show_files_listing()
}

pub async fn home(data: web::Data<AppState<'_>>) -> impl Responder {
    let context = json!({
        "currentPage": "home",
        "title": "Home",
    });

    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("home", &context).unwrap())
}

pub async fn about(data: web::Data<AppState<'_>>) -> impl Responder {
    let context = json!({
        "currentPage": "about",
        "title": "About",
    });

    HttpResponse::Ok()
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("about", &context).unwrap())
}

pub fn register_templates<'a>() -> Handlebars<'a> {
    templates::registry::register_templates()
}

pub async fn create_message_in_group(data: web::Data<AppState<'_>>, path: web::Path<String>, mut message_payload: web::Json<MessagePayload>) -> impl Responder {
    let message_group = &format!("{}", path);
    if !authorized(&message_group) {
        p404(data)
    } else {
        message_payload.message_group = message_group.to_string();
        let message_author_1 = env::var("MESSAGE_AUTHOR_1_ID")
            .unwrap_or_else(|_| "".to_string());
        message_payload.author = message_author_1;

        let key = format!("message{}", message_payload.index);
        let context = json!({
            "currentPage": "messages",
            "title": "Messages",
            key: message_payload.body,
        });

        let connection = db::establish_connection();
        db::create_message(&connection, &message_payload);

        HttpResponse::Created()
            .content_type("application/json; charset=utf-8")
            .json(context)
    }
}

pub async fn load_message_group(data: web::Data<AppState<'_>>, path: web::Path<String>) -> impl Responder {
    let message_group = format!("{}", path);
    if !authorized(&message_group) {
        p404(data)
    } else {
        let connection = db::establish_connection();
        let new_messages = db::message_bodies_for_group(&connection, &message_group);

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

        HttpResponse::Ok()
            .content_type("text/html; charset=utf-8")
            .body(data.template_registry.render("messages", &context).unwrap())
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
    let allowed_message_group = env::var("MESSAGE_GROUP_ID").unwrap();
    message_group == allowed_message_group
}
