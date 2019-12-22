
use diesel::Connection;
use diesel::pg::PgConnection;
use std::env;

use crate::schema;
use crate::models::{Message,NewMessage};
use crate::diesel::prelude::*;
use crate::MessagePayload;

pub fn establish_connection() -> PgConnection {
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    PgConnection::establish(&database_url)
        .expect(&format!("Error connecting to {}", database_url))
}

pub fn message_bodies_for_group<'a>(connection: &PgConnection, message_group: &str) -> Vec<String> {
    vec![load_message_body(&connection, message_group, 0),
         load_message_body(&connection, message_group, 1),
         load_message_body(&connection, message_group, 2),
         load_message_body(&connection, message_group, 3)]
}

pub fn load_message_body(connection: &PgConnection, message_group: &str, message_index: i32) -> String {
    let messages: Vec<Message>  = latest_messages(connection, message_group, message_index);

    let mut body = String::new();
    if messages.len() > 0 {
        match &messages[0].body {
            Some(val) => body = val.to_owned(),
            None => {}
        }
    }
    body
}

pub fn latest_messages(connection: &PgConnection, msg_group: &str, message_index: i32) -> Vec<Message> {
    use self::schema::messages::dsl::*;

    let latest_messages = messages.filter(message_group.eq(msg_group).and(index.eq(message_index)))
        .order(created_at.desc())
        .limit(1);

    latest_messages
        .load::<Message>(connection)
        .expect("Error loading messages")
}

pub fn create_message(connection: &PgConnection, message_payload: &MessagePayload) -> Message {
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
        .expect("Error saving new message")
}
