#[macro_use]
extern crate actix_web;
#[macro_use]
extern crate diesel;

use actix_files as fs;
use actix_web::http::{StatusCode};
use actix_web::{
    guard, middleware, web, App, HttpResponse, HttpServer, Result,
};
use diesel::pg::PgConnection;
use dotenv::dotenv;
use handlebars::Handlebars;
use listenfd::ListenFd;
use serde_json::json;
use serde::Deserialize;
use std::{env, io};
use actix_web_middleware_redirect_https::RedirectHTTPS;
use diesel::Connection;

pub mod schema;
pub mod models;

use self::models::{Message,NewMessage};
use self::diesel::prelude::*;

struct AppState {
    pub template_registry: Handlebars<'static>,
}

#[derive(Deserialize)]
struct MessagePayload {
    pub index: i32,
    pub body: String,
}

// Registers the Handlebars templates for the application.
fn register_templates() -> Result<Handlebars<'static>> {
    let mut template_registry = Handlebars::new();
    template_registry.set_strict_mode(true);
    let res =
        template_registry.register_template_file("application", "./src/templates/partials/application.hbs")
            .and_then(|_| { template_registry.register_template_file("header", "./src/templates/partials/header.hbs") })
            .and_then(|_| { template_registry.register_template_file("home", "./src/templates/home.hbs") })
            .and_then(|_| { template_registry.register_template_file("404", "./src/templates/404.hbs") })
            .and_then(|_| { template_registry.register_template_file("messages", "./src/templates/messages.hbs") })
            .and_then(|_| { template_registry.register_template_file("about", "./src/templates/about.hbs") });
    if res.is_err() {
        panic!("Could not register template")
    }

    Ok(template_registry)
}

pub fn establish_connection() -> PgConnection {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url))
}

fn load_message_body(connection: &PgConnection, _message_group: &String, message_index: i32) -> String {
    let messages: Vec<Message>  = latest_messages(connection, message_index);

    let mut body = String::new();
    if messages.len() > 0 {
        match &messages[0].body {
            Some(val) => body = val.to_owned(),
            None => {}
        }
    }
    body
}

fn latest_messages(connection: &PgConnection, message_index: i32) -> Vec<Message> {
    use self::schema::messages::dsl::*;

    let latest_messages = messages.filter(index.eq(message_index))
        .order(created_at.desc())
        .limit(1)
        .load::<Message>(connection)
        .expect("Error loading messages");

    latest_messages
}

fn create_message<'a>(connection: &PgConnection, message_group: &'a str, body: &'a str, index: &'a i32, message_author: &'a str) -> Message {
    use self::schema::messages;

    let new_message = NewMessage {
        message_group: message_group,
        body: body,
        index: index,
        message_author: message_author,
    };

    diesel::insert_into(messages::table)
        .values(&new_message)
        .get_result(connection)
        .expect("Error saving new message")
}

fn serve_favicon() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/favicon.ico")?)
}

#[get("/favicon")]
fn favicon() -> Result<fs::NamedFile> {
    serve_favicon()
}

#[get("/favicon.ico")]
fn favicon_ico() -> Result<fs::NamedFile> {
    serve_favicon()
}

#[get("/style.css")]
fn css() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/style.css")?)
}

#[get("/quill/quill.min.js")]
fn quill_js() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/quill/quill.min.js")?)
}

#[get("/quill/quill.snow.css")]
fn quill_css() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/quill/quill.snow.css")?)
}

#[get("/images/charles-river-compressed.png")]
fn charles() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/images/charles-river-compressed.png")?)
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

    let connection = establish_connection();
    let message_author_0 = env::var("MESSAGE_AUTHOR_0_ID")
        .unwrap_or_else(|_| "".to_string());
    let message_author_1 = env::var("MESSAGE_AUTHOR_1_ID")
        .unwrap_or_else(|_| "".to_string());

    let new_message_0 = NewMessage {
        message_group: &message_group.clone(),
        body: &load_message_body(&connection, &message_group, 0),
        index: &0,
        message_author: &message_author_0.clone(),
    };

    let new_message_1 = NewMessage {
        message_group: &message_group.clone(),
        body: &load_message_body(&connection, &message_group, 1),
        index: &1,
        message_author: &message_author_1.clone(),
    };

    let new_message_2 = NewMessage {
        message_group: &message_group.clone(),
        body: &load_message_body(&connection, &message_group, 2),
        index: &2,
        message_author: &message_author_1.clone(),
    };

    let context = json!({
        "currentPage": "messages",
        "title": "Messages",
        "message_0": new_message_0.body,
        "message_1": new_message_1.body,
        "message_2": new_message_2.body,
        "messageGroup": message_group,
    });

    Ok(HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("messages", &context).unwrap()))
}

fn create_message_in_group(path: web::Path<String>, message_payload: web::Json<MessagePayload>) -> Result<HttpResponse> {
    let connection = establish_connection();

    let message_group = &format!("{}", path);

    let key = format!("message_{}", message_payload.index);
    let context = json!({
        "currentPage": "messages",
        "title": "Messages",
        key: message_payload.body,
    });

    create_message(&connection, message_group, &"abc", &message_payload.index, "a");

    Ok(HttpResponse::build(StatusCode::CREATED)
        .content_type("application/json; charset=utf-8")
        .json(context))
}

fn main() -> io::Result<()> {
    dotenv().ok();
    env::set_var("RUST_LOG", "actix_web=debug");
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
                template_registry: register_templates().unwrap(),
            })
            .wrap(middleware::Condition::new(redirect_to_https, RedirectHTTPS::default()))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            // register favicon
            .service(favicon)
            .service(favicon_ico)
            .service(fs::Files::new("/static", "static").show_files_listing())
            .service(css)
            .service(quill_js)
            .service(quill_css)
            .service(charles)
            // register simple route, handle all methods
            .service(home)
            .service(about)
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
