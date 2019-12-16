table! {
    messages (id) {
        id -> Int4,
        created_at -> Timestamp,
        updated_at -> Timestamp,
        body -> Nullable<Jsonb>,
        message_group -> Text,
        index -> Int4,
        message_author -> Text,
    }
}
