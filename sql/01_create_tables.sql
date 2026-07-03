DROP TABLE IF EXISTS ticket_events;
DROP TABLE IF EXISTS support_tickets;
DROP TABLE IF EXISTS cashback_operations;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    registration_date DATE NOT NULL,
    city VARCHAR(100) NOT NULL,
    segment VARCHAR(30) NOT NULL
);

CREATE TABLE cashback_operations (
    operation_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    operation_date TIMESTAMP NOT NULL,
    purchase_amount NUMERIC(10, 2) NOT NULL CHECK (purchase_amount > 0),
    cashback_amount NUMERIC(10, 2) NOT NULL CHECK (cashback_amount >= 0),
    expected_cashback_date DATE NOT NULL,
    actual_cashback_date DATE,
    cashback_status VARCHAR(30) NOT NULL,
    merchant_category VARCHAR(100) NOT NULL,
    is_visible_in_app BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE support_tickets (
    ticket_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
    operation_id INTEGER REFERENCES cashback_operations(operation_id),
    parent_ticket_id INTEGER REFERENCES support_tickets(ticket_id),
    created_at TIMESTAMP NOT NULL,
    topic VARCHAR(100) NOT NULL,
    channel VARCHAR(30) NOT NULL,
    ticket_status VARCHAR(30) NOT NULL,
    first_response_at TIMESTAMP,
    resolved_at TIMESTAMP,
    resolution_type VARCHAR(100),
    was_resolved_by_bot BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE ticket_events (
    event_id SERIAL PRIMARY KEY,
    ticket_id INTEGER NOT NULL REFERENCES support_tickets(ticket_id) ON DELETE CASCADE,
    event_time TIMESTAMP NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    actor VARCHAR(30) NOT NULL,
    comment TEXT
);