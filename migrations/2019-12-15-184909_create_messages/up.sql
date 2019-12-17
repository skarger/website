CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  body TEXT,
  message_group TEXT NOT NULL,
  index INTEGER NOT NULL,
  message_author TEXT NOT NULL
);

SELECT diesel_manage_updated_at('messages');

CREATE INDEX idx_messages_on_message_group ON messages (message_group);
