use actix_web::dev::Service;
use actix_web::{test, web, App};
use web_server;

#[test]
fn about_get() {
    let mut app = test::init_service(
        App::new()
            .data(web_server::request_data())
            .route("/about", web::get().to(web_server::about)));
    let req = test::TestRequest::get().uri("/about").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_success());
}

