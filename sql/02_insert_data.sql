INSERT INTO customers (registration_date, city, segment)
VALUES
    ('2024-01-10', 'Москва', 'premium'),
    ('2024-02-15', 'Санкт-Петербург', 'standard'),
    ('2024-03-20', 'Казань', 'basic'),
    ('2024-04-05', 'Екатеринбург', 'standard'),
    ('2024-05-12', 'Москва', 'basic');

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
VALUES
    (1, '2026-04-01 12:00', 1000, 50, '2026-04-10', '2026-04-10', 'credited', 'Супермаркеты', TRUE),
    (2, '2026-04-02 15:30', 2500, 125, '2026-04-12', NULL, 'pending', 'Кафе и рестораны', FALSE),
    (3, '2026-04-03 18:10', 1800, 90, '2026-04-13', '2026-04-18', 'credited_late', 'Транспорт', FALSE),
    (4, '2026-04-04 11:40', 3200, 160, '2026-04-14', '2026-04-14', 'credited', 'Аптеки', TRUE),
    (5, '2026-04-05 20:00', 5000, 250, '2026-04-15', '2026-04-19', 'credited_late', 'Онлайн-магазины', TRUE),
    (1, '2026-04-06 13:15', 700, 35, '2026-04-16', NULL, 'pending', 'Супермаркеты', TRUE),
    (2, '2026-04-07 09:20', 1500, 75, '2026-04-17', '2026-04-17', 'credited', 'Транспорт', FALSE),
    (3, '2026-04-08 17:50', 4200, 210, '2026-04-18', '2026-04-22', 'credited_late', 'Кафе и рестораны', FALSE);


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
VALUES
    (2, 2, NULL, '2026-04-13 10:00', 'cashback_pending', 'chat', 'resolved', '2026-04-13 10:35', '2026-04-13 16:00', 'operator_explanation_without_eta', FALSE),
    (2, 2, 1, '2026-04-15 11:00', 'cashback_not_received', 'chat', 'resolved', '2026-04-15 11:20', '2026-04-15 15:00', 'operator_explanation_with_eta', FALSE),

    (3, 3, NULL, '2026-04-14 12:00', 'cashback_delayed', 'mobile_app', 'resolved', '2026-04-14 12:35', '2026-04-14 18:00', 'operator_explanation_without_eta', FALSE),
    (3, 3, 3, '2026-04-16 13:00', 'cashback_not_received', 'chat', 'resolved', '2026-04-16 13:20', '2026-04-16 17:00', 'operator_explanation_with_eta', FALSE),

    (1, 1, NULL, '2026-04-11 09:00', 'cashback_not_received', 'chat', 'resolved', '2026-04-11 09:05', '2026-04-11 09:30', 'bot_status_explanation', TRUE),
    (4, 4, NULL, '2026-04-15 10:30', 'cashback_not_received', 'chat', 'resolved', '2026-04-15 10:35', '2026-04-15 11:00', 'bot_status_explanation', TRUE),

    (5, 5, NULL, '2026-04-16 14:00', 'cashback_delayed', 'phone', 'resolved', '2026-04-16 14:35', '2026-04-16 20:00', 'operator_explanation_with_eta', FALSE),
    (1, 6, NULL, '2026-04-17 15:00', 'cashback_pending', 'mobile_app', 'resolved', '2026-04-17 15:35', '2026-04-17 21:00', 'operator_explanation_with_eta', FALSE),
    (3, 8, NULL, '2026-04-19 16:00', 'cashback_delayed', 'chat', 'resolved', '2026-04-19 16:35', '2026-04-19 22:00', 'operator_explanation_without_eta', FALSE);


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
    'Клиент создал обращение'
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
    'first_response',
    CASE
        WHEN was_resolved_by_bot THEN 'bot'
        ELSE 'operator'
    END,
    'Клиент получил первый ответ'
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