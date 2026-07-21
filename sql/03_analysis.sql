# всего обращений в поддержку

SELECT COUNT(*) AS total_tickets
FROM support_tickets;


# обращений были первыми

SELECT COUNT(*) AS initial_tickets
FROM support_tickets
WHERE parent_ticket_id IS NULL;


# обращений были повторными

SELECT COUNT(*) AS repeated_tickets
FROM support_tickets
WHERE parent_ticket_id IS NOT NULL;


# обращения являются повторными

SELECT
    ticket_id,
    customer_id,
    operation_id,
    parent_ticket_id,
    created_at,
    topic,
    channel
FROM support_tickets
WHERE parent_ticket_id IS NOT NULL;


# По каким статусам кэшбэка чаще создаются обращения

SELECT
    co.cashback_status,
    COUNT(*) AS ticket_count
FROM support_tickets st
JOIN cashback_operations co
    ON st.operation_id = co.operation_id
GROUP BY co.cashback_status
ORDER BY ticket_count DESC;


# Влияет ли видимость кэшбэка в приложении на обращения

SELECT
    co.is_visible_in_app,
    COUNT(*) AS ticket_count
FROM support_tickets st
JOIN cashback_operations co
    ON st.operation_id = co.operation_id
GROUP BY co.is_visible_in_app
ORDER BY ticket_count DESC;


# Какие операции привели к повторному обращению

SELECT
    st.ticket_id,
    st.parent_ticket_id,
    st.customer_id,
    co.cashback_status,
    co.is_visible_in_app,
    co.expected_cashback_date,
    co.actual_cashback_date
FROM support_tickets st
JOIN cashback_operations co
    ON st.operation_id = co.operation_id
WHERE st.parent_ticket_id IS NOT NULL;


# Сколько обращений решил бот и сколько оператор

SELECT
    was_resolved_by_bot,
    COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY was_resolved_by_bot;


# Среднее время решения обращения ботом и оператором

SELECT
    was_resolved_by_bot,
    AVG(resolved_at - created_at) AS avg_resolution_time
FROM support_tickets
WHERE parent_ticket_id IS NULL
GROUP BY was_resolved_by_bot;