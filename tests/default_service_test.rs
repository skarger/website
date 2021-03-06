use actix_web::{test, http::StatusCode, App};
use web_server;

mod common { pub mod environment; }
use crate::common::environment::load_env;

#[actix_rt::test]
async fn default_service() {
    load_env();

    let mut app = test::init_service(
        App::new()
            .configure(web_server::config)
            .default_service(web_server::default_service()))
            .await;

    let req = test::TestRequest::get().uri("/unknown").to_request();
    let resp = test::call_service(&mut app,req).await;

    assert!(resp.status().is_client_error(), "GET to unknown route returns 400-level error");
    assert_eq!(resp.status(), StatusCode::NOT_FOUND, "GET to unknown route returns 404");

    let req = test::TestRequest::post().uri("/unknown").to_request();
    let resp = test::call_service(&mut app,req).await;

    assert!(resp.status().is_client_error(), "POST to unknown route returns 400-level error");
    assert_eq!(resp.status(), StatusCode::METHOD_NOT_ALLOWED, "POST to unknown route returns 405");
}

