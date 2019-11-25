#[macro_use]
extern crate actix_web;

use actix_files as fs;
use actix_web::http::{StatusCode};
use actix_web::{
    guard, middleware, web, App, HttpResponse, HttpServer, Result,
};
use handlebars::Handlebars;
use listenfd::ListenFd;
use serde_json::json;
use std::{env, io};

struct AppState {
    pub template_registry: Handlebars<'static>,
}

// Registers the Handlebars templates for the application.
fn register_templates() -> Result<Handlebars<'static>> {
    let mut template_registry = Handlebars::new();
    template_registry.set_strict_mode(true);
    let res =
        template_registry.register_template_file("application", "./src/templates/partials/application.hbs")
            .and_then(|_| { template_registry.register_template_file("header", "./src/templates/partials/header.hbs") })
        .and_then(|_| { template_registry.register_template_file("home", "./src/templates/home.hbs") })
            .and_then(|_| { template_registry.register_template_file("about", "./src/templates/about.hbs") });
    if res.is_err() {
        panic!("Could not register template")
    }

    Ok(template_registry)
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

#[get("/images/charles-river-compressed.png")]
fn charles() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/images/charles-river-compressed.png")?)
}

fn p404() -> Result<fs::NamedFile> {
    Ok(fs::NamedFile::open("static/404.html")?.set_status_code(StatusCode::NOT_FOUND))
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

fn main() -> io::Result<()> {
    env::set_var("RUST_LOG", "actix_web=debug");
    env_logger::init();

    let mut listenfd = ListenFd::from_env();

    // Get the port number to listen on.
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .expect("PORT must be a number");

    let mut server = HttpServer::new(|| {
        App::new()
            .data(AppState {
                template_registry: register_templates().unwrap(),
            })
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            // register favicon
            .service(favicon)
            .service(favicon_ico)
            .service(fs::Files::new("/static", "static").show_files_listing())
            .service(css)
            .service(charles)
            // register simple route, handle all methods
            .service(home)
            .service(about)
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
