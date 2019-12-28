use actix_files as fs;
use actix_web::{
    guard, middleware, web, App, HttpResponse, HttpServer
};
use actix_web_middleware_redirect_https::RedirectHTTPS;
use dotenv::dotenv;
use listenfd::ListenFd;
use std::{env, io};

use web_server::{self, AppState};

fn main() -> io::Result<()> {
    dotenv().ok();
    env::set_var("RUST_LOG", "actix_web=info,web=info");
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
                template_registry: web_server::register_templates(),
            })
            .wrap(middleware::Condition::new(redirect_to_https, RedirectHTTPS::default()))
            .wrap(middleware::Compress::default())
            .wrap(middleware::DefaultHeaders::new().header("Cache-Control", "max-age=0"))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            .service(fs::Files::new("/static", "static").show_files_listing())
            .route("/", web::get().to(web_server::home))
            .route("/favicon.ico", web::get().to(web_server::favicon))
            .route("/about", web::get().to(web_server::about))
            .route("/messages/{message_group}", web::get().to(web_server::load_message_group))
            .route("/messages/{message_group}", web::post().to(web_server::create_message_in_group))
            .default_service(
                // 404 for GET request
                web::resource("")
                    .route(web::get().to(web_server::p404))
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
