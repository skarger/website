use actix_web::http::{StatusCode};
use actix_web::{
    web, HttpResponse, Result,
};

use handlebars::Handlebars;
use serde::Deserialize;
use serde_json::json;

pub mod templates { pub mod registry; }

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

pub fn home(data: web::Data<AppState>) -> Result<HttpResponse> {
    let context = json!({
        "currentPage": "home",
        "title": "Home",
    });
    Ok(HttpResponse::build(StatusCode::OK)
        .content_type("text/html; charset=utf-8")
        .body(data.template_registry.render("home", &context).unwrap()))

}

pub fn register_templates<'a>() -> Handlebars<'a> {
    templates::registry::register_templates()
}
