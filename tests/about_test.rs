use actix_web::{test, App};
use web_server;

#[actix_rt::test]
async fn about_get() {
    let mut app = test::init_service(
        App::new()
            .configure(web_server::config))
            .await;
    let req = test::TestRequest::get().uri("/about").to_request();
    let resp = test::call_service(&mut app, req).await;

    assert!(resp.status().is_success());
}

