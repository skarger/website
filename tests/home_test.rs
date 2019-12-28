use actix_web::dev::Service;
use actix_web::{test, web, App};
use web_server;

#[test]
fn index_get() {
    let mut app = test::init_service(
        App::new()
            .data(web_server::AppState {
                template_registry: web_server::register_templates(),
            })
            .route("/", web::get().to(web_server::home)));
    let req = test::TestRequest::get().uri("/").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_success());
}

