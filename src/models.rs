use std::time::SystemTime;

#[derive(Queryable)]
pub struct Message {
    pub id: i32,
    pub created: SystemTime,
    pub updated: SystemTime,
    pub body: Option<String>,
    pub message_group: String,
    pub index: i32,
    pub message_author: String,
}

use super::schema::messages;

#[derive(Insertable)]
#[table_name="messages"]
pub struct NewMessage<'a> {
    pub message_group: &'a str,
    pub body: &'a str,
    pub index: &'a i32,
    pub message_author: &'a str,
}
