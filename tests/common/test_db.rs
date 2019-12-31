use diesel::Connection;
use diesel::pg::PgConnection;
use std::env;

pub fn establish_connection() -> PgConnection {
    let database_url = env::var("DATABASE_URL_TEST")
        .expect("DATABASE_URL_TEST must be set");
    PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url))
}