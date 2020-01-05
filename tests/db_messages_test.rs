use diesel::prelude::*;
use diesel::connection::Connection;
use diesel::dsl::count_star;
use web_server;
use web_server::{models, schema::messages::dsl::*};

mod common { pub mod environment; }
use crate::common::environment::load_env;

#[test]
fn create_message() {
    load_env();

    let message_payload = web_server::MessagePayload {
        message_group: String::from("mg1"),
        index: 0,
        body: String::from("body1"),
        author: String::from("author1"),
    };
    let conn = web_server::db::establish_connection();

    conn.test_transaction::<_, diesel::result::Error, _>(|| {
        let message_count = messages.select(count_star()).get_result(&conn);
        assert_eq!(Ok(0), message_count, "0 messages initially");

        web_server::db::create_message(&conn, &message_payload).expect("Failed to create message");

        let message_count = messages.select(count_star()).get_result(&conn);
        assert_eq!(Ok(1), message_count, "1 message created");

        let found_message = messages.first::<models::Message>(&conn).expect("Error loading messages");
        assert_eq!(found_message.message_group, String::from("mg1"));
        assert_eq!(found_message.index, 0);
        assert_eq!(found_message.message_author, String::from("author1"));
        assert_eq!(found_message.body, Some(String::from("body1")));

        Ok(())
    });
}
