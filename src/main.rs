use actix_web::{
    middleware, App, HttpServer
};
use dotenv::dotenv;
use log::info;
use std::{env};
use web_server;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv().ok();
    env::set_var("RUST_LOG", "actix_web=info,web_server=info");
    env_logger::init();

    let app_environment = env::var("APP_ENVIRONMENT")
        .unwrap_or("development".to_string());
    info!("Initializing in {} mode.", app_environment);

    let require_https = app_environment == "production" || app_environment == "staging";

    // Get the port number to listen on.
    let port = env::var("PORT")
        .unwrap_or("8080".to_string())
        .parse()
        .expect("PORT must be a number");

    let server = HttpServer::new(move || {
        info!("Starting server worker.");
        App::new()
            .wrap(middleware::Compress::default())
            .wrap(middleware::DefaultHeaders::new().header("Cache-Control", "max-age=0"))
            .wrap(middleware::Condition::new(require_https, web_server::RequireHttps))
            // enable logger - always register actix-web Logger middleware last
            .wrap(middleware::Logger::default())
            .configure(web_server::config)
            .default_service(web_server::default_service())
    });

    server.bind(("0.0.0.0", port))?.run().await
}
