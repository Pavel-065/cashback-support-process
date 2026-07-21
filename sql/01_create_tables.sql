CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    registration_date DATE,
    city VARCHAR(100),
    segment VARCHAR(30)
);

CREATE TABLE cashback_operations (
    operation_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    operation_date TIMESTAMP,
    purchase_amount NUMERIC(10, 2) CHECK (purchase_amount > 0),
    cashback_amount NUMERIC(10, 2)  CHECK (cashback_amount >= 0),
    expected_cashback_date DATE,
    actual_cashback_date DATE,
    cashback_status VARCHAR(30),
    merchant_category VARCHAR(100),
    is_visible_in_app BOOLEAN DEFAULT FALSE
);

CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(customer_id),
    operation_id INTEGER REFERENCES cashback_operations(operation_id),
    parent_ticket_id INTEGER REFERENCES support_tickets(ticket_id),
    created_at TIMESTAMP,
    topic VARCHAR(100),
    channel VARCHAR(30),
    ticket_status VARCHAR(30),
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_type VARCHAR(100),
    was_resolved_by_bot BOOLEAN DEFAULT FALSE
);

CREATE TABLE ticket_events (
    event_id SERIAL PRIMARY KEY,
    ticket_id INTEGER REFERENCES support_tickets(ticket_id) ON DELETE CASCADE,
    event_time TIMESTAMP,
    event_type VARCHAR(100),
    actor VARCHAR(30),
    comment TEXT
);

