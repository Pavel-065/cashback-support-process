TRUNCATE TABLE ticket_events, support_tickets, cashback_operations, customers
RESTART IDENTITY CASCADE;

INSERT INTO customers (registration_date, city, segment)
SELECT
    DATE '2024-01-01' + ((n * 17) % 720),
    CASE
        WHEN n % 4 = 0 THEN 'Москва'
        WHEN n % 4 = 1 THEN 'Санкт-Петербург'
        WHEN n % 4 = 2 THEN 'Казань'
        ELSE 'Екатеринбург'
    END,
    CASE
        WHEN n % 3 = 0 THEN 'premium'
        WHEN n % 3 = 1 THEN 'standard'
        ELSE 'basic'
    END
FROM generate_series(1, 100) AS g(n);

INSERT INTO cashback_operations (
    customer_id,
    operation_date,
    purchase_amount,
    cashback_amount,
    expected_cashback_date,
    actual_cashback_date,
    cashback_status,
    merchant_category,
    is_visible_in_app
)
SELECT
    ((n - 1) % 100) + 1,
    TIMESTAMP '2026-04-01 10:00:00'
        + (n % 60) * INTERVAL '1 day'
        + (n % 10) * INTERVAL '1 hour',
    (500 + ((n * 137) % 9500))::NUMERIC(10, 2),
    ROUND((500 + ((n * 137) % 9500)) * (1 + n % 5) / 100.0, 2),
    DATE '2026-04-01' + (n % 60) + 10,
    CASE
        WHEN n % 10 = 2 THEN NULL
        WHEN n % 10 IN (0, 1) THEN DATE '2026-04-01' + (n % 60) + 14
        ELSE DATE '2026-04-01' + (n % 60) + 9
    END,
    CASE
        WHEN n % 10 = 2 THEN 'pending'
        WHEN n % 10 IN (0, 1) THEN 'credited_late'
        ELSE 'credited'
    END,
    CASE
        WHEN n % 5 = 0 THEN 'Супермаркеты'
        WHEN n % 5 = 1 THEN 'Кафе и рестораны'
        WHEN n % 5 = 2 THEN 'Транспорт'
        WHEN n % 5 = 3 THEN 'Аптеки'
        ELSE 'Онлайн-магазины'
    END,
    n % 4 <> 0
FROM generate_series(1, 600) AS g(n);

WITH ticket_source AS (
    SELECT
        co.customer_id,
        co.operation_id,
        co.cashback_status,
        co.is_visible_in_app,
        CASE
            WHEN co.cashback_status = 'credited'
                THEN co.expected_cashback_date::TIMESTAMP + INTERVAL '1 day'
            ELSE co.expected_cashback_date::TIMESTAMP + INTERVAL '2 days'
        END AS created_at,
        CASE
            WHEN co.cashback_status = 'pending' THEN 'cashback_pending'
            WHEN co.cashback_status = 'credited_late' THEN 'cashback_delayed'
            ELSE 'cashback_not_received'
        END AS topic,
        CASE
            WHEN co.operation_id % 3 = 0 THEN 'chat'
            WHEN co.operation_id % 3 = 1 THEN 'mobile_app'
            ELSE 'phone'
        END AS channel
    FROM cashback_operations co
    WHERE co.cashback_status IN ('pending', 'credited_late')
       OR co.operation_id % 6 = 0
)
INSERT INTO support_tickets (
    customer_id,
    operation_id,
    parent_ticket_id,
    created_at,
    topic,
    channel,
    ticket_status,
    first_response_at,
    resolved_at,
    resolution_type,
    was_resolved_by_bot
)
SELECT
    customer_id,
    operation_id,
    NULL,
    created_at,
    topic,
    channel,
    'resolved',
    created_at +
        CASE
            WHEN cashback_status = 'credited' AND is_visible_in_app
                THEN INTERVAL '5 minutes'
            ELSE INTERVAL '35 minutes'
        END,
    created_at +
        CASE
            WHEN cashback_status = 'credited' AND is_visible_in_app
                THEN INTERVAL '30 minutes'
            ELSE INTERVAL '6 hours'
        END,
    CASE
        WHEN cashback_status = 'credited' AND is_visible_in_app
            THEN 'bot_status_explanation'
        ELSE 'operator_explanation_without_eta'
    END,
    cashback_status = 'credited' AND is_visible_in_app
FROM ticket_source;

INSERT INTO support_tickets (
    customer_id,
    operation_id,
    parent_ticket_id,
    created_at,
    topic,
    channel,
    ticket_status,
    first_response_at,
    resolved_at,
    resolution_type,
    was_resolved_by_bot
)
SELECT
    st.customer_id,
    st.operation_id,
    st.ticket_id,
    st.resolved_at + INTERVAL '2 days',
    'cashback_not_received',
    'chat',
    'resolved',
    st.resolved_at + INTERVAL '2 days 15 minutes',
    st.resolved_at + INTERVAL '2 days 4 hours',
    'operator_explanation_with_eta',
    FALSE
FROM support_tickets st
JOIN cashback_operations co
    ON st.operation_id = co.operation_id
WHERE st.parent_ticket_id IS NULL
  AND co.is_visible_in_app = FALSE
  AND co.cashback_status IN ('credited_late', 'pending');

INSERT INTO ticket_events (
    ticket_id,
    event_time,
    event_type,
    actor,
    comment
)
SELECT
    ticket_id,
    created_at,
    'ticket_created',
    'client',
    'Клиент обратился с вопросом о начислении кэшбэка'
FROM support_tickets;

INSERT INTO ticket_events (
    ticket_id,
    event_time,
    event_type,
    actor,
    comment
)
SELECT
    ticket_id,
    first_response_at,
    CASE
        WHEN was_resolved_by_bot THEN 'bot_response'
        ELSE 'operator_response'
    END,
    CASE
        WHEN was_resolved_by_bot THEN 'bot'
        ELSE 'operator'
    END,
    'Предоставлен ответ по статусу начисления кэшбэка'
FROM support_tickets;

INSERT INTO ticket_events (
    ticket_id,
    event_time,
    event_type,
    actor,
    comment
)
SELECT
    ticket_id,
    resolved_at,
    'ticket_resolved',
    CASE
        WHEN was_resolved_by_bot THEN 'bot'
        ELSE 'operator'
    END,
    'Обращение закрыто'
FROM support_tickets;

SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM customers
UNION ALL
SELECT 'cashback_operations', COUNT(*) FROM cashback_operations
UNION ALL
SELECT 'support_tickets', COUNT(*) FROM support_tickets
UNION ALL
SELECT 'ticket_events', COUNT(*) FROM ticket_events
ORDER BY table_name;