use std::env;
use std::task::{Context, Poll};
use actix_web::{
    Error, HttpResponse,
    http::{Uri, header},
    dev::{Service, Transform, ServiceRequest, ServiceResponse}
};
use futures::future::{ok, Either, Ready};

pub struct RequireHttps;

impl<S, B> Transform<S> for RequireHttps
    where
        S: Service<Request = ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
        S::Future: 'static,
{
    type Request = ServiceRequest;
    type Response = ServiceResponse<B>;
    type Error = Error;
    type InitError = ();
    type Transform = RequireHttpsMiddleware<S>;
    type Future = Ready<Result<Self::Transform, Self::InitError>>;

    fn new_transform(&self, service: S) -> Self::Future {
        ok(RequireHttpsMiddleware { service })
    }
}
pub struct RequireHttpsMiddleware<S> {
    service: S,
}

impl<S, B> Service for RequireHttpsMiddleware<S>
    where
        S: Service<Request = ServiceRequest, Response = ServiceResponse<B>, Error = Error>,
        S::Future: 'static,
{
    type Request = ServiceRequest;
    type Response = ServiceResponse<B>;
    type Error = Error;
    type Future = Either<S::Future, Ready<Result<Self::Response, Self::Error>>>;

    fn poll_ready(&mut self, cx: &mut Context) -> Poll<Result<(), Self::Error>> {
        self.service.poll_ready(cx)
    }

    fn call(&mut self, req: ServiceRequest) -> Self::Future {
        if is_https(&req) {
            Either::Left(self.service.call(req))
        } else {
            let transformed_url = transform_url(&req);
            Either::Right(ok(req.into_response(
                HttpResponse::Found()
                    .header(header::LOCATION, transformed_url)
                    .finish()
                    .into_body(),
            )))
        }
    }
}

fn is_https(req: &ServiceRequest) -> bool {
    let conn_info = req.connection_info();
    conn_info.scheme() == "https"
}

fn transform_url(req: &ServiceRequest) -> String {
    let conn_info = req.connection_info();
    let default_host = env::var("URI_AUTHORITY").unwrap_or(String::from(""));
    let host = if conn_info.host().len() > 0 {
        conn_info.host()
    } else {
        default_host.as_str()
    };
    let path_and_query = req.uri().path_and_query().map_or("", |v| v.as_str());

    let url = Uri::builder()
        .scheme("https")
        .authority(host)
        .path_and_query(path_and_query)
        .build()
        .unwrap();

    format!("{}", url)
}
