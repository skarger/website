use diesel::Connection;
use diesel::pg::PgConnection;
use log::warn;
use std::env;

use crate::schema;
use crate::models::{Message,NewMessage};
use crate::diesel::prelude::*;
use crate::MessagePayload;
use diesel::r2d2::ConnectionManager;

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
        .max_size(8) // by default actix spins up 8 server workers, the N of logical CPUs on a Heroku hobby dev dyno
        .connection_timeout(Duration::new(10, 0))
        .build(manager);

    if pool.is_err() {
        warn!("Could not create connection pool.")
    }

    pool.unwrap()
}

pub fn message_bodies_for_group<'a>(connection: &PgConnection, message_group: &str) -> Result<Vec<String>, diesel::result::Error> {
    Ok(vec![load_message_body(&connection, message_group, 0)?,
         load_message_body(&connection, message_group, 1)?,
         load_message_body(&connection, message_group, 2)?,
         load_message_body(&connection, message_group, 3)?])
}

pub fn load_message_body(connection: &PgConnection, message_group: &str, message_index: i32) -> Result<String, diesel::result::Error> {
    let messages: Vec<Message>  = latest_messages(connection, message_group, message_index)?;

    let mut body = String::new();
    if messages.len() > 0 {
        match &messages[0].body {
            Some(val) => body = val.to_owned(),
            None => {}
        }
    }
    Ok(body)
}

pub fn latest_messages(connection: &PgConnection, msg_group: &str, message_index: i32) -> diesel::result::QueryResult<Vec<Message>> {
    use self::schema::messages::dsl::*;

    let latest_messages = messages.filter(message_group.eq(msg_group).and(index.eq(message_index)))
        .order(created_at.desc())
        .limit(1);

    latest_messages.load::<Message>(connection)
}

pub fn create_message(connection: &PgConnection, message_payload: &MessagePayload) -> diesel::result::QueryResult<Message> {
    use self::schema::messages;

    let new_message = NewMessage {
        message_group: &message_payload.message_group,
        body: &message_payload.body,
        index: &message_payload.index,
        message_author: &message_payload.author,
    };

    diesel::insert_into(messages::table)
        .values(&new_message)
        .get_result(connection)
}
