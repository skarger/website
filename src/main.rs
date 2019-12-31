use actix_web::{
    middleware, App, HttpServer
};
//use actix_web_middleware_redirect_https::RedirectHTTPS;
use dotenv::dotenv;
use listenfd::ListenFd;
use std::{env, io};

use web_server;

#[actix_rt::main]
async fn main() -> io::Result<()> {
    dotenv().ok();
    env::set_var("RUST_LOG", "actix_web=info,web=info");
    env_logger::init();

    let mut listenfd = ListenFd::from_env();

//    let app_environment = env::var("APP_ENVIRONMENT")
//        .unwrap_or_else(|_| "development".to_string());
//
//    let redirect_to_https = app_environment == "production" || app_environment == "staging";

    // Get the port number to listen on.
    let port = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .expect("PORT must be a number");

    let mut server = HttpServer::new(move || {
        App::new()
//            .wrap(middleware::Condition::new(redirect_to_https, RedirectHTTPS::default()))
            .wrap(middleware::Compress::default())
            .wrap(middleware::DefaultHeaders::new().header("Cache-Control", "max-age=0"))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            .configure(web_server::config)
            .default_service(web_server::default_service())
    });

    server = if let Some(l) = listenfd.take_tcp_listener(0).unwrap() {
        server.listen(l)?
    } else {
        server.bind(("0.0.0.0", port))?
    };

    server.run().await
}
