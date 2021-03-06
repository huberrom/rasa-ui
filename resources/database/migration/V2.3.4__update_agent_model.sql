SET search_path TO rasa_ui;

-- Alter Agent Table
ALTER TABLE agents ADD COLUMN rasa_nlu_threshold REAL DEFAULT 0.3;

DROP VIEW messages_expressions;

-- Add column confidence to view messages_expressions
CREATE OR REPLACE VIEW messages_expressions AS
SELECT agents.agent_id, agents.agent_name,
       msg.messages_id, msg.timestamp, msg.user_id, msg.user_name, msg.message_text, msg.message_rich, msg.user_message_ind,
       expressions.expression_id, intent_confidence_pct,
       CASE
         WHEN((cast(nlu_parse_log.intent_confidence_pct as decimal) / 100) < agents.rasa_nlu_threshold) THEN null
         ELSE intents.intent_id
       END AS intent_id,
       CASE
         WHEN((cast(nlu_parse_log.intent_confidence_pct as decimal) / 100) < agents.rasa_nlu_threshold) THEN null
         ELSE intents.intent_name
       END AS intent_name
FROM messages AS msg
       INNER JOIN agents ON msg.agent_id = agents.agent_id
       LEFT OUTER JOIN intents ON msg.intent_id = intents.intent_id
       LEFT JOIN expressions ON (intents.intent_id = expressions.intent_id) AND (msg.message_text = expressions.expression_text)
       LEFT JOIN nlu_parse_log ON msg.messages_id = nlu_parse_log.messages_id
ORDER BY timestamp, user_id;

GRANT ALL ON TABLE messages_expressions TO ${postgres_user};