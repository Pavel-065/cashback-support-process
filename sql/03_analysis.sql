SELECT
    COUNT(*) AS total_tickets,
    COUNT(*) FILTER (WHERE parent_ticket_id IS NULL) AS initial_tickets,
    COUNT(*) FILTER (WHERE parent_ticket_id IS NOT NULL) AS repeated_tickets,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE parent_ticket_id IS NOT NULL) / COUNT(*),
        2
    ) AS repeated_ticket_share_pct
FROM support_tickets;


WITH first_tickets AS (
    SELECT
        st.ticket_id,
        co.cashback_status,
        co.is_visible_in_app
    FROM support_tickets st
    JOIN cashback_operations co
        ON st.operation_id = co.operation_id
    WHERE st.parent_ticket_id IS NULL
),
repeats AS (
    SELECT
        parent_ticket_id,
        COUNT(*) AS repeat_count
    FROM support_tickets
    WHERE parent_ticket_id IS NOT NULL
    GROUP BY parent_ticket_id
)
SELECT
    cashback_status,
    CASE
        WHEN is_visible_in_app THEN 'виден в приложении'
        ELSE 'не виден в приложении'
    END AS cashback_visibility,
    COUNT(*) AS initial_tickets,
    COUNT(repeats.parent_ticket_id) AS tickets_with_repeat,
    ROUND(
        100.0 * COUNT(repeats.parent_ticket_id) / COUNT(*),
        2
    ) AS repeat_share_pct
FROM first_tickets
LEFT JOIN repeats
    ON first_tickets.ticket_id = repeats.parent_ticket_id
GROUP BY
    cashback_status,
    is_visible_in_app
ORDER BY repeat_share_pct DESC;

SELECT
    CASE
        WHEN was_resolved_by_bot THEN 'бот'
        ELSE 'оператор'
    END AS resolution_method,
    COUNT(*) AS ticket_count,
    ROUND(
        AVG(EXTRACT(EPOCH FROM first_response_at - created_at) / 60),
        2
    ) AS avg_first_response_minutes,
    ROUND(
        AVG(EXTRACT(EPOCH FROM resolved_at - created_at) / 60),
        2
    ) AS avg_resolution_minutes
FROM support_tickets
WHERE parent_ticket_id IS NULL
GROUP BY was_resolved_by_bot
ORDER BY avg_resolution_minutes;