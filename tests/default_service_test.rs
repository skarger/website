use actix_web::dev::Service;
use actix_web::{test, http::StatusCode, App};
use web_server;

#[test]
fn default_service() {
    let mut app = test::init_service(
        App::new()
            .configure(web_server::config)
            .default_service(web_server::default_service()));

    let req = test::TestRequest::get().uri("/unknown").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_client_error());
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);

    let req = test::TestRequest::post().uri("/unknown").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_client_error());
    assert_eq!(resp.status(), StatusCode::METHOD_NOT_ALLOWED);
}

