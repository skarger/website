#[macro_use]
extern crate actix_web;
#[macro_use]
extern crate diesel;

use actix_files as fs;
use actix_web::http::{StatusCode};
use actix_web::{
    guard, middleware, web, App, HttpResponse, HttpServer, Result,
};

use dotenv::dotenv;
use handlebars::Handlebars;
use listenfd::ListenFd;
use serde_json::json;
use serde::Deserialize;
use std::{env, io};
use actix_web_middleware_redirect_https::RedirectHTTPS;

pub mod schema;
pub mod models;
pub mod db;
pub mod templates { pub mod registry; }

use self::db::{establish_connection, message_bodies_for_group, create_message};
use self::templates::registry as template_registry;

struct AppState<'a> {
    pub template_registry: Handlebars<'a>,
}

#[derive(Deserialize)]
pub struct MessagePayload {
    pub message_group: String,
    pub index: i32,
    pub body: String,
    pub author: String,
}



fn create_message_in_group(data: web::Data<AppState>, path: web::Path<String>, mut message_payload: web::Json<MessagePayload>) -> Result<HttpResponse> {
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

        let connection = establish_connection();
        create_message(&connection, &message_payload);

        Ok(HttpResponse::build(StatusCode::CREATED)
            .content_type("application/json; charset=utf-8")
            .json(context))
    }
}

fn p404(data: web::Data<AppState>) -> Result<HttpResponse> {
    let context = json!({
        "currentPage": "404",
        "title": "Not Found",
    });
    Ok(HttpResponse::build(StatusCode::NOT_FOUND)
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("404", &context).unwrap()))
}

#[get("/favicon.ico")]
fn favicon() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/favicon.ico")?)
}

#[get("/")]
fn home(data: web::Data<AppState>) -> Result<HttpResponse> {
    let context = json!({
        "currentPage": "home",
        "title": "Home",
    });
    Ok(HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("home", &context).unwrap()))
}

#[get("/about")]
fn about(data: web::Data<AppState>) -> Result<HttpResponse> {
    let context = json!({
        "currentPage": "about",
        "title": "About",
    });
    Ok(HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("about", &context).unwrap()))
}

fn load_message_group(data: web::Data<AppState>, path: web::Path<String>) -> Result<HttpResponse> {
    let message_group = format!("{}", path);
    if !authorized(&message_group) {
        p404(data)
    } else {
        let connection = establish_connection();
        let new_messages = message_bodies_for_group(&connection, &message_group);

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

        Ok(HttpResponse::build(StatusCode::OK)
            .content_type("text/html; charset=utf-8")
            .body(data.template_registry.render("messages", &context).unwrap()))
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

fn main() -> io::Result<()> {
    dotenv().ok();
    std::env::set_var("RUST_LOG", "actix_web=info,web=info");
    env_logger::init();

    let mut listenfd = ListenFd::from_env();

    let app_environment = env::var("APP_ENVIRONMENT")
        .unwrap_or_else(|_| "development".to_string());

    // Get the port number to listen on.
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .expect("PORT must be a number");

    let redirect_to_https = app_environment == "production" || app_environment == "staging";

    let mut server = HttpServer::new(move || {
        App::new()
            .data(AppState {
                template_registry: template_registry::register_templates(),
            })
            .wrap(middleware::Condition::new(redirect_to_https, RedirectHTTPS::default()))
            .wrap(middleware::Compress::default())
            .wrap(middleware::DefaultHeaders::new().header("Cache-Control", "max-age=0"))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            .service(fs::Files::new("/static", "static").show_files_listing())
            // register simple route, handle all methods
            .service(home)
            .service(about)
            .service(favicon)
            .route("/messages/{message_group}", web::get().to(load_message_group))
            .route("/messages/{message_group}", web::post().to(create_message_in_group))
            .default_service(
                // 404 for GET request
                web::resource("")
                    .route(web::get().to(p404))
                    // all requests that are not `GET`
                    .route(
                        web::route()
                            .guard(guard::Not(guard::Get()))
                            .to(HttpResponse::MethodNotAllowed),
                    ),
            )
    });

    server = if let Some(l) = listenfd.take_tcp_listener(0).unwrap() {
        server.listen(l).unwrap()
    } else {
        server.bind(("0.0.0.0", port)).unwrap()
    };

    server.run()
}
