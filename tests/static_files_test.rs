use actix_web::{test, App, http::StatusCode};
use web_server;

mod common { pub mod environment; }
use crate::common::environment::load_env;

#[actix_rt::test]
async fn static_get() {
    load_env();

    let mut app = test::init_service(
        App::new()
            .configure(web_server::config))
            .await;

    let req = test::TestRequest::get().uri("/static/404.html").to_request();
    let resp = test::call_service(&mut app,req).await;
    assert!(resp.status().is_success(), "Successfully serves static 404 page");

    let req = test::TestRequest::get().uri("/static/favicon.ico").to_request();
    let resp = test::call_service(&mut app,req).await;
    assert!(resp.status().is_success(), "Successfully serves favicon");

    let req = test::TestRequest::get().uri("/static/unknown.jpg").to_request();
    let resp = test::call_service(&mut app,req).await;
    assert!(resp.status().is_client_error(), "Returns 400-level error for unknown static file");
    assert_eq!(resp.status(), StatusCode::NOT_FOUND, "Returns 404 for unknown static file");
}

