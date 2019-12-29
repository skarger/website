use actix_web::dev::Service;
use actix_web::{test, App};
use web_server;

#[test]
fn about_get() {
    let mut app = test::init_service(
        App::new()
            .configure(web_server::config));
    let req = test::TestRequest::get().uri("/about").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_success());
}

