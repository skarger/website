use actix_web::{test, App};
use web_server;

mod common { pub mod environment; }
use crate::common::environment::load_env;

#[actix_rt::test]
async fn index_get() {
    load_env();

    let mut app = test::init_service(
        App::new()
            .configure(web_server::config))
            .await;

    let req = test::TestRequest::get().uri("/").to_request();
    let resp = test::call_service(&mut app, req).await;

    assert!(resp.status().is_success());
}

