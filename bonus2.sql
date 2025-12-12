
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(255) UNIQUE,
    status VARCHAR(20) CHECK (status IN ('active','blocked','frozen')) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    daily_limit_kzt NUMERIC(18,2) DEFAULT 1000000
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT','USD','EUR','RUB')) NOT NULL,
    balance NUMERIC(18,2) DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(18,2) NOT NULL,
    currency VARCHAR(3) CHECK (currency IN ('KZT','USD','EUR','RUB')) NOT NULL,
    exchange_rate NUMERIC(18,6),
    amount_kzt NUMERIC(18,2),
    type VARCHAR(20) CHECK (type IN ('transfer','deposit','withdrawal')) NOT NULL,
    status VARCHAR(20) CHECK (status IN ('pending','completed','failed','reversed')) DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    description TEXT
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) CHECK (from_currency IN ('KZT','USD','EUR','RUB')) NOT NULL,
    to_currency VARCHAR(3) CHECK (to_currency IN ('KZT','USD','EUR','RUB')) NOT NULL,
    rate NUMERIC(18,6) NOT NULL,
    valid_from TIMESTAMP NOT NULL,
    valid_to TIMESTAMP
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    action VARCHAR(10) CHECK (action IN ('INSERT','UPDATE','DELETE')) NOT NULL,
    old_values JSONB,
    new_values JSONB,
    changed_by VARCHAR(100),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address INET
);


INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('990101123456', 'Aigerim Saparova', '+77011234567', 'aigerim@example.com', 'active', 2000000),
('880202234567', 'Nurlan Beketov', '+77021234567', 'nurlan@example.com', 'active', 1500000),
('770303345678', 'Dana Karimova', '+77031234567', 'dana@example.com', 'active', 1000000),
('660404456789', 'Yerlan Tursynov', '+77041234567', 'yerlan@example.com', 'blocked', 500000),
('550505567890', 'Alina Zhumabaeva', '+77051234567', 'alina@example.com', 'active', 2500000),
('440606678901', 'Serik Mukhamedov', '+77061234567', 'serik@example.com', 'active', 1200000),
('330707789012', 'Madina Omarova', '+77071234567', 'madina@example.com', 'active', 1800000),
('220808890123', 'Dias Kenzhebek', '+77081234567', 'dias@example.com', 'frozen', 800000),
('110909901234', 'Aruzhan Abilova', '+77091234567', 'aruzhan@example.com', 'active', 3000000),
('001010012345', 'Timur Zhaksylykov', '+77101234567', 'timur@example.com', 'active', 2000000);

INSERT INTO accounts (customer_id, account_number, currency, balance) VALUES
(1, 'KZ123456789000000001', 'KZT', 1500000),
(1, 'KZ123456789000000002', 'USD', 5000),
(2, 'KZ123456789000000003', 'KZT', 800000),
(3, 'KZ123456789000000004', 'EUR', 2000),
(4, 'KZ123456789000000005', 'KZT', 100000),
(5, 'KZ123456789000000006', 'USD', 12000),
(6, 'KZ123456789000000007', 'RUB', 300000),
(7, 'KZ123456789000000008', 'KZT', 2200000),
(8, 'KZ123456789000000009', 'EUR', 500),
(9, 'KZ123456789000000010', 'KZT', 3500000);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from) VALUES
('USD','KZT', 470.50, NOW()),
('EUR','KZT', 510.75, NOW()),
('RUB','KZT', 5.20, NOW()),
('KZT','USD', 0.0021, NOW()),
('KZT','EUR', 0.0019, NOW()),
('KZT','RUB', 0.19, NOW()),
('USD','EUR', 0.92, NOW()),
('EUR','USD', 1.08, NOW()),
('USD','RUB', 90.00, NOW()),
('RUB','USD', 0.011, NOW());

INSERT INTO transactions (from_account_id, to_account_id, amount, currency, exchange_rate, amount_kzt, type, status, description) VALUES
(1, 3, 200000, 'KZT', 1, 200000, 'transfer', 'completed', 'Payment to Nurlan'),
(2, 4, 1000, 'USD', 470.50, 470500, 'transfer', 'completed', 'USD to EUR transfer'),
(3, 5, 50000, 'KZT', 1, 50000, 'transfer', 'failed', 'Insufficient balance'),
(6, 7, 2000, 'USD', 470.50, 941000, 'transfer', 'completed', 'Business payment'),
(8, 9, 100, 'EUR', 510.75, 51075, 'transfer', 'completed', 'Gift transfer'),
(9, 1, 300000, 'KZT', 1, 300000, 'transfer', 'completed', 'Refund'),
(5, 2, 2000, 'USD', 470.50, 941000, 'transfer', 'completed', 'Family support'),
(7, 10, 100000, 'RUB', 5.20, 520000, 'transfer', 'completed', 'Rapid transfer'),
(10, 6, 500000, 'KZT', 1, 500000, 'withdrawal', 'completed', 'Cash withdrawal'),
(4, 8, 50, 'EUR', 510.75, 25537.5, 'transfer', 'completed', 'Small transfer');

INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by, ip_address) VALUES
('customers', 1, 'UPDATE', '{"status":"active"}', '{"status":"blocked"}', 'admin', '192.168.1.10'),
('accounts', 2, 'UPDATE', '{"balance":5000}', '{"balance":4500}', 'system', '192.168.1.11'),
('transactions', 1, 'INSERT', NULL, '{"status":"completed"}', 'system', '192.168.1.12'),
('transactions', 3, 'UPDATE', '{"status":"pending"}', '{"status":"failed"}', 'system', '192.168.1.13'),
('customers', 4, 'UPDATE', '{"status":"active"}', '{"status":"blocked"}', 'admin', '192.168.1.14'),
('accounts', 5, 'DELETE', '{"account_number":"KZ123456789000000005"}', NULL, 'admin', '192.168.1.15'),
('exchange_rates', 1, 'UPDATE', '{"rate":470.50}', '{"rate":471.00}', 'system', '192.168.1.16'),
('transactions', 6, 'INSERT', NULL, '{"status":"completed"}', 'system', '192.168.1.17'),
('audit_log', 2, 'INSERT', NULL, '{"action":"UPDATE"}', 'system', '192.168.1.18'),
('customers', 7, 'UPDATE', '{"daily_limit_kzt":1800000}', '{"daily_limit_kzt":2000000}', 'admin', '192.168.1.19');


-- Task 1
CREATE OR REPLACE FUNCTION process_transfer(
    from_account_number VARCHAR,
    to_account_number VARCHAR,
    transfer_amount NUMERIC,
    transfer_currency VARCHAR,
    transfer_description TEXT
) RETURNS VOID AS $$
DECLARE
    v_from_account_id INT;
    v_to_account_id INT;
    v_from_customer_id INT;
    v_customer_status VARCHAR(20);
    v_balance NUMERIC;
    v_daily_limit NUMERIC;
    v_today_total NUMERIC;
    v_exchange_rate NUMERIC := 1;
    v_amount_kzt NUMERIC;
    v_tx_id INT;
BEGIN
    SELECT account_id, customer_id, balance
    INTO v_from_account_id, v_from_customer_id, v_balance
    FROM accounts
    WHERE account_number = from_account_number AND is_active = TRUE
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERR01: Source account not found or inactive';
    END IF;

    SELECT account_id
    INTO v_to_account_id
    FROM accounts
    WHERE account_number = to_account_number AND is_active = TRUE
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'ERR02: Destination account not found or inactive';
    END IF;

    SELECT status, daily_limit_kzt
    INTO v_customer_status, v_daily_limit
    FROM customers
    WHERE customer_id = v_from_customer_id;

    IF v_customer_status <> 'active' THEN
        RAISE EXCEPTION 'ERR03: Customer status is %', v_customer_status;
    END IF;

    IF v_balance < transfer_amount THEN
        RAISE EXCEPTION 'ERR04: Insufficient funds';
    END IF;

    SELECT COALESCE(SUM(amount_kzt),0)
    INTO v_today_total
    FROM transactions
    WHERE from_account_id = v_from_account_id
      AND created_at::date = CURRENT_DATE
      AND status = 'completed';

    IF transfer_currency <> 'KZT' THEN
        SELECT rate INTO v_exchange_rate
        FROM exchange_rates
        WHERE from_currency = transfer_currency AND to_currency = 'KZT'
          AND valid_from <= NOW()
          AND (valid_to IS NULL OR valid_to >= NOW())
        ORDER BY valid_from DESC
        LIMIT 1;

        IF v_exchange_rate IS NULL THEN
            RAISE EXCEPTION 'ERR05: Exchange rate not found';
        END IF;
    END IF;

    v_amount_kzt := transfer_amount * v_exchange_rate;

    IF v_today_total + v_amount_kzt > v_daily_limit THEN
        RAISE EXCEPTION 'ERR06: Daily limit exceeded';
    END IF;

    BEGIN
        UPDATE accounts
        SET balance = balance - transfer_amount
        WHERE account_id = v_from_account_id;

        UPDATE accounts
        SET balance = balance + transfer_amount
        WHERE account_id = v_to_account_id;

        INSERT INTO transactions(
            from_account_id, to_account_id, amount, currency,
            exchange_rate, amount_kzt, type, status, description
        ) VALUES (
            v_from_account_id, v_to_account_id, transfer_amount, transfer_currency,
            v_exchange_rate, v_amount_kzt, 'transfer', 'completed', transfer_description
        )
        RETURNING transaction_id INTO v_tx_id;

        INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by, ip_address)
        VALUES ('transactions', v_tx_id, 'INSERT',
                jsonb_build_object('amount', transfer_amount, 'currency', transfer_currency),
                current_user, inet_client_addr());
    EXCEPTION WHEN OTHERS THEN
        INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by, ip_address)
        VALUES ('transactions', 0, 'INSERT',
                jsonb_build_object('error', SQLERRM),
                current_user, inet_client_addr());
        RAISE;
    END;
END;
$$ LANGUAGE plpgsql;

-- Tests
-- 1. Успешный перевод (счёт 1 → счёт 3, KZT)
SELECT process_transfer(
    'KZ123456789000000001',
    'KZ123456789000000003',
    100000,
    'KZT',
    'Test successful transfer'
);

-- 2. Недостаток средств (счёт 3 → счёт 6, KZT, баланс меньше суммы)
SELECT process_transfer(
    'KZ123456789000000003',
    'KZ123456789000000006',
    2000000,
    'KZT',
    'Test insufficient funds'
);

-- 3. Превышение дневного лимита (счёт 1 → счёт 3, слишком большая сумма)
SELECT process_transfer(
    'KZ123456789000000001',
    'KZ123456789000000003',
    3000000,
    'KZT',
    'Test daily limit exceeded'
);

-- 4. Неактивный клиент (счёт 5 принадлежит клиенту со статусом blocked)
SELECT process_transfer(
    'KZ123456789000000005',
    'KZ123456789000000003',
    50000,
    'KZT',
    'Test blocked customer'
);

-- 5. Ошибка курса валют (перевод в валюте, которой нет в exchange_rates)
SELECT process_transfer(
    'KZ123456789000000002',
    'KZ123456789000000004',
    100,
    'GBP',
    'Test missing exchange rate'
);



-- Task 2
-- 1. Customer Balance Summary
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH balances AS (
    SELECT
        c.customer_id,
        c.full_name,
        a.account_id,
        a.account_number,
        a.currency,
        a.balance,
        COALESCE(er.rate, 1) AS rate_to_kzt,
        a.balance * COALESCE(er.rate, 1) AS balance_kzt,
        c.daily_limit_kzt
    FROM customers c
    JOIN accounts a ON c.customer_id = a.customer_id
    LEFT JOIN exchange_rates er
           ON a.currency = er.from_currency
          AND er.to_currency = 'KZT'
          AND er.valid_from <= NOW()
          AND (er.valid_to IS NULL OR er.valid_to >= NOW())
),
customer_totals AS (
    SELECT
        customer_id,
        SUM(balance_kzt) AS total_balance_kzt
    FROM balances
    GROUP BY customer_id
),
ranked_totals AS (
    SELECT
        customer_id,
        total_balance_kzt,
        RANK() OVER (ORDER BY total_balance_kzt DESC) AS balance_rank
    FROM customer_totals
)
SELECT
    b.customer_id,
    b.full_name,
    b.account_id,
    b.account_number,
    b.currency,
    b.balance,
    b.rate_to_kzt,
    b.balance_kzt,
    ct.total_balance_kzt,
    ROUND((ct.total_balance_kzt / NULLIF(b.daily_limit_kzt, 0)) * 100, 2) AS daily_limit_utilization_pct,
    rt.balance_rank
FROM balances b
JOIN customer_totals ct ON ct.customer_id = b.customer_id
JOIN ranked_totals rt ON rt.customer_id = b.customer_id;

-- 2. Daily Transaction Report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH daily AS (
    SELECT
        t.created_at::date AS tx_date,
        t.type,
        SUM(t.amount_kzt) AS total_volume_kzt,
        COUNT(*) AS tx_count,
        AVG(t.amount_kzt) AS avg_amount_kzt
    FROM transactions t
    WHERE t.status = 'completed'
    GROUP BY t.created_at::date, t.type
),
daily_totals AS (
    SELECT
        tx_date,
        SUM(total_volume_kzt) AS day_total_kzt
    FROM daily
    GROUP BY tx_date
)
SELECT
    d.tx_date,
    d.type,
    d.tx_count,
    d.total_volume_kzt,
    d.avg_amount_kzt,
    SUM(dt.day_total_kzt) OVER (ORDER BY dt.tx_date) AS running_total_kzt,
    ROUND(
        (dt.day_total_kzt - LAG(dt.day_total_kzt) OVER (ORDER BY dt.tx_date))
        / NULLIF(LAG(dt.day_total_kzt) OVER (ORDER BY dt.tx_date), 0) * 100,
        2
    ) AS day_over_day_growth_pct
FROM daily d
JOIN daily_totals dt ON dt.tx_date = d.tx_date
ORDER BY d.tx_date, d.type;

-- 3. Suspicious Activity View
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount,
    t.amount_kzt,
    t.created_at,
    CASE
        WHEN t.amount_kzt > 5000000 THEN 'Large transaction'
        WHEN COUNT(*) OVER (
                 PARTITION BY t.from_account_id, date_trunc('hour', t.created_at)
             ) > 10 THEN 'High frequency in hour'
        WHEN EXTRACT(
                 EPOCH FROM (
                     t.created_at - LAG(t.created_at) OVER (
                         PARTITION BY t.from_account_id ORDER BY t.created_at
                     )
                 )
             ) < 60 THEN 'Rapid sequential transfers'
        ELSE NULL
    END AS suspicious_reason
FROM transactions t
WHERE t.status = 'completed';

-- Tests
-- Проверка customer_balance_summary
SELECT * FROM customer_balance_summary
ORDER BY balance_rank
LIMIT 10;

-- Проверка daily_transaction_report
SELECT * FROM daily_transaction_report
ORDER BY tx_date DESC, type;

-- Проверка suspicious_activity_view
SELECT * FROM suspicious_activity_view
WHERE suspicious_reason IS NOT NULL;



-- Task 3
-- B-tree index
CREATE INDEX idx_accounts_account_number
    ON accounts USING btree (account_number);

-- Composite index
CREATE INDEX idx_transactions_from_account_date
    ON transactions USING btree (from_account_id, created_at);

-- Partial index
CREATE INDEX idx_active_accounts
    ON accounts USING btree (customer_id)
    WHERE is_active = TRUE;

-- Expression index
CREATE INDEX idx_customers_email_lower
    ON customers (lower(email));

-- GIN index
CREATE INDEX idx_audit_log_jsonb
    ON audit_log USING gin (new_values);

-- Hash index
CREATE INDEX idx_accounts_currency_hash
    ON accounts USING hash (currency);

-- Covering index
CREATE INDEX idx_transactions_covering
    ON transactions (from_account_id, created_at, status)
    INCLUDE (amount_kzt, description);

-- Tests
-- Проверка B-tree индекса
EXPLAIN ANALYZE SELECT * FROM accounts WHERE account_number = 'KZ123456789000000001';

-- Проверка composite индекса
EXPLAIN ANALYZE SELECT * FROM transactions
WHERE from_account_id = 1 AND created_at::date = CURRENT_DATE;

-- Проверка partial индекса
EXPLAIN ANALYZE SELECT * FROM accounts WHERE is_active = TRUE AND customer_id = 1;

-- Проверка expression индекса
EXPLAIN ANALYZE SELECT * FROM customers WHERE lower(email) = lower('aigerim@example.com');

-- Проверка GIN индекса
EXPLAIN ANALYZE SELECT * FROM audit_log WHERE new_values @> '{"status":"blocked"}';

-- Проверка hash индекса
EXPLAIN ANALYZE SELECT * FROM accounts WHERE currency = 'USD';

-- Проверка covering индекса
EXPLAIN ANALYZE SELECT from_account_id, created_at, status, amount_kzt, description
FROM transactions WHERE from_account_id = 1 AND status = 'completed';



-- Task 4
CREATE OR REPLACE FUNCTION process_salary_batch(
    company_account_number VARCHAR,
    payments JSONB
) RETURNS JSONB AS $$
DECLARE
    v_company_account_id INT;
    v_company_currency VARCHAR(3);
    v_company_balance NUMERIC;
    v_success_count INT := 0;
    v_failed_count INT := 0;
    v_failed_details JSONB := '[]'::JSONB;
    v_total_amount NUMERIC := 0;
    v_elem JSONB;
    v_iin CHAR(12);
    v_amount NUMERIC;
    v_desc TEXT;
    v_customer_id INT;
    v_customer_status VARCHAR(20);
    v_recipient_account_id INT;
    v_recipient_currency VARCHAR(3);
    v_rate_to_recipient NUMERIC := 1;
    v_rate_to_kzt NUMERIC := 1;
    v_amount_recipient NUMERIC;
    v_amount_kzt NUMERIC;
    v_tx_id INT;
BEGIN
    PERFORM pg_advisory_lock(hashtext(company_account_number));
    SELECT account_id, currency, balance
    INTO v_company_account_id, v_company_currency, v_company_balance
    FROM accounts
    WHERE account_number = company_account_number AND is_active = TRUE
    FOR UPDATE;
    IF NOT FOUND THEN
        PERFORM pg_advisory_unlock(hashtext(company_account_number));
        RAISE EXCEPTION 'ERRB01: Company account not found or inactive';
    END IF;

    SELECT COALESCE(SUM((p->>'amount')::NUMERIC), 0)
    INTO v_total_amount
    FROM jsonb_array_elements(payments) AS p;
    IF v_company_balance < v_total_amount THEN
        PERFORM pg_advisory_unlock(hashtext(company_account_number));
        RAISE EXCEPTION 'ERRB02: Insufficient company balance for batch: % < %', v_company_balance, v_total_amount;
    END IF;

    CREATE TEMP TABLE IF NOT EXISTS tmp_salary_deltas (
        account_id INT PRIMARY KEY,
        delta NUMERIC
    ) ON COMMIT DROP;

    DELETE FROM tmp_salary_deltas;
    INSERT INTO tmp_salary_deltas(account_id, delta) VALUES (v_company_account_id, 0)
    ON CONFLICT (account_id) DO NOTHING;

    FOR v_elem IN SELECT * FROM jsonb_array_elements(payments)
    LOOP
        v_iin := (v_elem->>'iin')::CHAR(12);
        v_amount := (v_elem->>'amount')::NUMERIC;
        v_desc := COALESCE(v_elem->>'description', 'Salary payment');

        SELECT customer_id, status
        INTO v_customer_id, v_customer_status
        FROM customers
        WHERE iin = v_iin;

        IF v_customer_id IS NULL OR v_customer_status <> 'active' THEN
            v_failed_details := v_failed_details || jsonb_build_array(jsonb_build_object('iin', v_iin, 'amount', v_amount, 'reason', 'Customer not found or inactive'));
            v_failed_count := v_failed_count + 1;
            CONTINUE;
        END IF;

        SELECT account_id, currency
        INTO v_recipient_account_id, v_recipient_currency
        FROM accounts
        WHERE customer_id = v_customer_id AND is_active = TRUE
          AND currency = v_company_currency
        ORDER BY opened_at
        LIMIT 1;

        IF v_recipient_account_id IS NULL THEN
            SELECT account_id, currency
            INTO v_recipient_account_id, v_recipient_currency
            FROM accounts
            WHERE customer_id = v_customer_id AND is_active = TRUE
              AND currency = 'KZT'
            ORDER BY opened_at
            LIMIT 1;
        END IF;

        IF v_recipient_account_id IS NULL THEN
            v_failed_details := v_failed_details || jsonb_build_array(jsonb_build_object('iin', v_iin, 'amount', v_amount, 'reason', 'No active recipient account'));
            v_failed_count := v_failed_count + 1;
            CONTINUE;
        END IF;

        IF v_company_currency <> v_recipient_currency THEN
            SELECT rate
            INTO v_rate_to_recipient
            FROM exchange_rates
            WHERE from_currency = v_company_currency AND to_currency = v_recipient_currency
              AND valid_from <= NOW()
              AND (valid_to IS NULL OR valid_to >= NOW())
            ORDER BY valid_from DESC
            LIMIT 1;
            IF v_rate_to_recipient IS NULL THEN
                v_failed_details := v_failed_details || jsonb_build_array(jsonb_build_object('iin', v_iin, 'amount', v_amount, 'reason', 'Exchange rate not found'));
                v_failed_count := v_failed_count + 1;
                CONTINUE;
            END IF;
        ELSE
            v_rate_to_recipient := 1;
        END IF;

        IF v_company_currency <> 'KZT' THEN
            SELECT rate
            INTO v_rate_to_kzt
            FROM exchange_rates
            WHERE from_currency = v_company_currency AND to_currency = 'KZT'
              AND valid_from <= NOW()
              AND (valid_to IS NULL OR valid_to >= NOW())
            ORDER BY valid_from DESC
            LIMIT 1;
            IF v_rate_to_kzt IS NULL THEN
                v_failed_details := v_failed_details || jsonb_build_array(jsonb_build_object('iin', v_iin, 'amount', v_amount, 'reason', 'Rate to KZT not found'));
                v_failed_count := v_failed_count + 1;
                CONTINUE;
            END IF;
        ELSE
            v_rate_to_kzt := 1;
        END IF;

        v_amount_recipient := v_amount * v_rate_to_recipient;
        v_amount_kzt := v_amount * v_rate_to_kzt;

        BEGIN
            INSERT INTO transactions(
                from_account_id, to_account_id, amount, currency,
                exchange_rate, amount_kzt, type, status, description
            ) VALUES (
                v_company_account_id, v_recipient_account_id, v_amount, v_company_currency,
                v_rate_to_kzt, v_amount_kzt, 'transfer', 'pending', v_desc
            ) RETURNING transaction_id INTO v_tx_id;

            INSERT INTO audit_log(table_name, record_id, action, new_values, changed_by, ip_address)
            VALUES ('transactions', v_tx_id, 'INSERT',
                    jsonb_build_object('amount', v_amount, 'currency', v_company_currency, 'salary', TRUE),
                    current_user, inet_client_addr());

            INSERT INTO tmp_salary_deltas(account_id, delta)
            VALUES (v_recipient_account_id, v_amount_recipient)
            ON CONFLICT (account_id) DO UPDATE SET delta = tmp_salary_deltas.delta + EXCLUDED.delta;

            UPDATE tmp_salary_deltas
            SET delta = delta - v_amount
            WHERE account_id = v_company_account_id;

            v_success_count := v_success_count + 1;
        EXCEPTION WHEN OTHERS THEN
            v_failed_details := v_failed_details || jsonb_build_array(jsonb_build_object('iin', v_iin, 'amount', v_amount, 'reason', SQLERRM));
            v_failed_count := v_failed_count + 1;
        END;
    END LOOP;

    UPDATE accounts a
    SET balance = a.balance + d.delta
    FROM tmp_salary_deltas d
    WHERE a.account_id = d.account_id;

    UPDATE transactions
    SET status = 'completed', completed_at = NOW()
    WHERE from_account_id = v_company_account_id AND status = 'pending';

    PERFORM pg_advisory_unlock(hashtext(company_account_number));

    RETURN jsonb_build_object(
        'successful_count', v_success_count,
        'failed_count', v_failed_count,
        'failed_details', v_failed_details
    );
EXCEPTION WHEN OTHERS THEN
    PERFORM pg_advisory_unlock(hashtext(company_account_number));
    RAISE;
END;
$$ LANGUAGE plpgsql;


CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
    t.created_at::date AS pay_date,
    COUNT(*) AS payments_count,
    SUM(t.amount_kzt) AS total_kzt,
    MIN(t.amount_kzt) AS min_kzt,
    MAX(t.amount_kzt) AS max_kzt,
    AVG(t.amount_kzt) AS avg_kzt
FROM transactions t
WHERE t.type = 'transfer' AND t.status = 'completed' AND t.description ILIKE '%salary%'
GROUP BY t.created_at::date;

CREATE UNIQUE INDEX idx_salary_batch_summary_unique ON salary_batch_summary (pay_date);

REFRESH MATERIALIZED VIEW CONCURRENTLY salary_batch_summary;



-- Tests
-- 1. Успешный пакет выплат (двое сотрудников, активные счета)
SELECT process_salary_batch(
    'KZ123456789000000006',
    '[{"iin":"990101123456","amount":5000,"description":"Test salary"},
      {"iin":"880202234567","amount":7000,"description":"Test salary"}]'::jsonb
);

-- 2. Недостаток средств (сумма выплат больше баланса компании)
SELECT process_salary_batch(
    'KZ123456789000000006',
    '[{"iin":"770303345678","amount":99999999,"description":"Oversized salary"}]'::jsonb
);

-- 3. Заблокированный клиент (счёт 5 принадлежит клиенту со статусом blocked)
SELECT process_salary_batch(
    'KZ123456789000000005',
    '[{"iin":"660404456789","amount":50000,"description":"Blocked customer salary"}]'::jsonb
);

-- 4. Ошибка курса валют (выплата в GBP, курса нет в exchange_rates)
SELECT process_salary_batch(
    'KZ123456789000000002',
    '[{"iin":"110909901234","amount":1000,"description":"Salary in GBP"}]'::jsonb
);

-- 5. Проверка отчёта по зарплатным выплатам (материализованное представление)
SELECT * FROM salary_batch_summary ORDER BY pay_date DESC;