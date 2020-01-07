use diesel::Connection;
use diesel::pg::PgConnection;
use diesel::r2d2::ConnectionManager;
use log::warn;
use std::env;


pub type ConnectionPool = diesel::r2d2::Pool<ConnectionManager<PgConnection>>;
pub type PooledConnection = diesel::r2d2::PooledConnection<ConnectionManager<PgConnection>>;

pub fn establish_connection() -> PgConnection {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url))
}

pub fn connection_pool() -> ConnectionPool {
    use std::time::Duration;

    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let manager = diesel::r2d2::ConnectionManager::<PgConnection>::new(database_url);
    let pool = diesel::r2d2::Pool::builder()
        .max_size(1)
        .connection_timeout(Duration::new(10, 0))
        .build(manager);

    if pool.is_err() {
        warn!("Could not create connection pool.")
    }

    pool.unwrap()
}

