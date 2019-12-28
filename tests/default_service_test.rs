use actix_web::dev::Service;
use actix_web::{test, web, guard, App, HttpResponse};
use actix_web::http::{StatusCode};

use web_server;

#[test]
fn default_service() {
    let mut app = test::init_service(
        App::new()
            .data(web_server::request_data())
            .default_service(
                // 404 for GET request
                web::resource("")
                    .route(web::get().to(web_server::p404))
                    // all requests that are not `GET`
                    .route(
                        web::route()
                            .guard(guard::Not(guard::Get()))
                            .to(HttpResponse::MethodNotAllowed),
                    ),
            )

    );
    let req = test::TestRequest::get().uri("/unknown").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_client_error());
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);

    let req = test::TestRequest::post().uri("/unknown").to_request();
    let resp = test::block_on(app.call(req)).unwrap();

    assert!(resp.status().is_client_error());
    assert_eq!(resp.status(), StatusCode::METHOD_NOT_ALLOWED);
}

