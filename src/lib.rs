use actix_files::NamedFile;
use actix_files as fs;
use actix_web::{
    HttpResponse, Resource, Result,
    web, guard, error, http::StatusCode,
};

use handlebars::Handlebars;
use log::warn;
use serde_json::json;
use std::{fmt};

pub mod db;
pub mod models;
pub mod schema;
pub mod templates { pub mod registry; }
pub mod require_https;

pub use require_https::RequireHttps;

pub struct ApplicationState<'a> {
    pub template_registry: Handlebars<'a>,
    pub connection_pool: db::ConnectionPool,
}

#[derive(fmt::Debug)]
pub struct ApplicationError {}

impl fmt::Display for ApplicationError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        write!(f, "{}", error_body())
    }
}

impl error::ResponseError for ApplicationError {
    fn status_code(&self) -> StatusCode {
        StatusCode::INTERNAL_SERVER_ERROR
    }

    fn error_response(&self) -> HttpResponse {
        HttpResponse::build(self.status_code())
            .content_type("text/html; charset=utf-8")
            .body(self.to_string())
    }
}

pub fn config(cfg: &mut web::ServiceConfig) {
    cfg.data(app_state())
        .service(static_files())
        .route("/favicon.ico", web::get().to(favicon))
        .route("/", web::get().to(home))
        .route("/about", web::get().to(about))
        .route("/error", web::get().to(test_error));
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
        connection_pool: db::connection_pool(),
    }
}

pub fn error_body() -> String {
    let mut registry = Handlebars::new();
    let registration = registry.register_template_file("application", "./src/templates/partials/application.hbs")
        .and_then(|_| registry.register_template_file("header", "./src/templates/partials/header.hbs"))
        .and_then(|_| registry.register_template_file("500", "./src/templates/500.hbs"));
    if registration.is_err() {
        warn!("ApplicationError: could not register error template");
    }

    let context = json!({
            "currentPage": "500",
            "title": "Internal Server Error",
        });
    let error_html = registry.render("500", &context);
    error_html.unwrap_or("Internal Server Error".to_string())
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

pub async fn test_error() -> Result<&'static str, ApplicationError> {
    Err(ApplicationError {})
}

pub fn static_files() -> fs::Files {
    fs::Files::new("/static", "static").show_files_listing()
}

pub async fn home(data: web::Data<ApplicationState<'_>>) -> Result<HttpResponse, ApplicationError> {
    let context = json!({
        "currentPage": "home",
        "title": "Home",
    });

    render_html(data, StatusCode::OK, "home", context)
}

pub fn render_html(data: web::Data<ApplicationState>, status_code: StatusCode, template_name: &str, context: serde_json::Value) -> Result<HttpResponse, ApplicationError> {
    match data.template_registry.render(template_name, &context) {
        Ok(s) => {
            Ok(HttpResponse::build(status_code)
                .content_type("text/html; charset=utf-8")
                .body(s))
        },
        Err(_) => Err(ApplicationError {})
    }
}

pub async fn about(data: web::Data<ApplicationState<'_>>) -> Result<HttpResponse, ApplicationError> {
    let context = json!({
        "currentPage": "about",
        "title": "About",
    });

    render_html(data, StatusCode::OK, "about", context)
}

pub fn register_templates<'a>() -> Handlebars<'a> {
    templates::registry::register_templates()
}

