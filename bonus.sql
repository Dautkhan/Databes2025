BEGIN;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin VARCHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone VARCHAR(20),
    email TEXT,
    status VARCHAR(10) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    daily_limit_kzt NUMERIC(18,2) DEFAULT 1000000
);
CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id) ON DELETE CASCADE,
    account_number VARCHAR(34) UNIQUE NOT NULL,
    currency VARCHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance NUMERIC(20,4) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT true,
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    closed_at TIMESTAMP WITH TIME ZONE
);
CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency VARCHAR(3) NOT NULL,
    to_currency VARCHAR(3) NOT NULL,
    rate NUMERIC(18,8) NOT NULL,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    valid_to TIMESTAMP WITH TIME ZONE
);

CREATE TABLE transactions (
    transaction_id BIGSERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(20,4) NOT NULL,
    currency VARCHAR(3) NOT NULL,
    exchange_rate NUMERIC(18,8),
    amount_kzt NUMERIC(20,4),
    type VARCHAR(20) NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    completed_at TIMESTAMP WITH TIME ZONE,
    description TEXT
);

CREATE TABLE audit_log (
    log_id BIGSERIAL PRIMARY KEY,
    table_name TEXT,
    record_id TEXT,
    action VARCHAR(10),
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    ip_address TEXT
);

INSERT INTO customers(iin, full_name, phone, email, status, daily_limit_kzt)
VALUES
('870101200123','Aman Berikov','+7-701-0000001','aman@example.com','active',5000000),
('880202300234','Zhanar Abay','+7-701-0000002','zhanar@example.com','active',2000000),
('890303400345','Serik Toleu','+7-701-0000003','serik@example.com','blocked',1000000),
('900404500456','Gulnar Sapar','+7-701-0000004','gulnar@example.com','active',3000000),
('910505600567','Erbol Nurbek','+7-701-0000005','erbol@example.com','active',1000000),
('920606700678','Aigerim Zhumagali','+7-701-0000006','aigerim@example.com','active',2500000),
('930707800789','Murat Kenzhe','+7-701-0000007','murat@example.com','frozen',1500000),
('940808900890','Leyla Omar','+7-701-0000008','leyla@example.com','active',1000000),
('950909001901','Timur Iskakov','+7-701-0000009','timur@example.com','active',500000),
('961010112012','Dana Karim','+7-701-0000010','dana@example.com','active',2000000);

INSERT INTO accounts(customer_id,account_number,currency,balance,is_active)
VALUES
(1,'KZ01BANK00000000000001','KZT',1000000,true),
(1,'KZ01BANK00000000000002','USD',2000,true),
(2,'KZ01BANK00000000000003','KZT',500000,true),
(2,'KZ01BANK00000000000004','EUR',1000,true),
(3,'KZ01BANK00000000000005','KZT',10000,true),
(4,'KZ01BANK00000000000006','RUB',50000,true),
(5,'KZ01BANK00000000000007','KZT',200000,true),
(6,'KZ01BANK00000000000008','USD',500,true),
(7,'KZ01BANK00000000000009','KZT',10000,false),
(8,'KZ01BANK00000000000010','KZT',750000,true),
(9,'KZ01BANK00000000000011','EUR',50,true),
(10,'KZ01BANK00000000000012','KZT',1200000,true);

INSERT INTO exchange_rates(from_currency,to_currency,rate)
VALUES
('USD','KZT',470),
('EUR','KZT',510),
('RUB','KZT',6.5),
('KZT','KZT',1),
('USD','EUR',0.92),
('EUR','USD',1.09);

INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description)
VALUES
(1,3,100000,'KZT',1,100000,'transfer','completed','Test transfer'),
(2,4,100,'USD',470,47000,'transfer','completed','USD to EUR'),
(10,5,50000,'KZT',1,50000,'transfer','completed','Blocked test');

-- AUDIT TRIGGERS

CREATE OR REPLACE FUNCTION audit_log_trigger_fn()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP='DELETE' THEN
        INSERT INTO audit_log(table_name,record_id,action,old_values,new_values,changed_by)
        VALUES (TG_TABLE_NAME, OLD.*::text, 'DELETE', to_jsonb(OLD), NULL, current_user);
        RETURN OLD;
    ELSIF TG_OP='UPDATE' THEN
        INSERT INTO audit_log(table_name,record_id,action,old_values,new_values,changed_by)
        VALUES (TG_TABLE_NAME, NEW.*::text, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
        RETURN NEW;
    ELSE
        INSERT INTO audit_log(table_name,record_id,action,new_values,changed_by)
        VALUES (TG_TABLE_NAME, NEW.*::text, 'INSERT', to_jsonb(NEW), current_user);
        RETURN NEW;
    END IF;
END $$;

CREATE TRIGGER audit_customers AFTER INSERT OR UPDATE OR DELETE ON customers
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger_fn();
CREATE TRIGGER audit_accounts AFTER INSERT OR UPDATE OR DELETE ON accounts
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger_fn();
CREATE TRIGGER audit_transactions AFTER INSERT OR UPDATE OR DELETE ON transactions
FOR EACH ROW EXECUTE FUNCTION audit_log_trigger_fn();

-- TASK 1: process_transfer


CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account VARCHAR,
    p_to_account VARCHAR,
    p_amount NUMERIC,
    p_currency VARCHAR,
    p_description TEXT DEFAULT NULL
)
RETURNS TABLE(code TEXT, message TEXT)
LANGUAGE plpgsql AS $$
DECLARE
    a_from RECORD;
    a_to RECORD;
    c_sender RECORD;
    rate NUMERIC;
    total_today NUMERIC;
    amount_kzt NUMERIC;
BEGIN
    -- Validate accounts
    SELECT * INTO a_from FROM accounts WHERE account_number=p_from_account FOR UPDATE;
    IF NOT FOUND THEN
        code := 'ERR_NO_SOURCE'; message := 'Source account not found'; RETURN;
    END IF;

    SELECT * INTO a_to FROM accounts WHERE account_number=p_to_account FOR UPDATE;
    IF NOT FOUND THEN
        code := 'ERR_NO_DEST'; message := 'Destination account not found'; RETURN;
    END IF;

    IF a_from.is_active=false THEN
        code:='ERR_SRC_INACTIVE'; message:='Source inactive'; RETURN;
    END IF;
    IF a_to.is_active=false THEN
        code:='ERR_DST_INACTIVE'; message:='Destination inactive'; RETURN;
    END IF;

    SELECT * INTO c_sender FROM customers WHERE customer_id=a_from.customer_id;
    IF c_sender.status <> 'active' THEN
        code:='ERR_SENDER_BLOCKED'; message:='Sender is not active'; RETURN;
    END IF;

    -- Exchange rate
    SELECT rate INTO rate FROM exchange_rates
    WHERE from_currency=p_currency AND to_currency='KZT'
    ORDER BY rate_id DESC LIMIT 1;

    IF rate IS NULL THEN
        code:='ERR_RATE_NOT_FOUND'; message:='Exchange rate missing'; RETURN;
    END IF;

    amount_kzt := p_amount * rate;

    -- Daily limit check
    SELECT COALESCE(SUM(amount_kzt),0) INTO total_today
    FROM transactions t JOIN accounts a ON a.account_id=t.from_account_id
    WHERE a.customer_id=c_sender.customer_id
      AND t.status='completed'
      AND t.created_at::date = now()::date;

    IF total_today + amount_kzt > c_sender.daily_limit_kzt THEN
        code := 'ERR_DAILY_LIMIT'; message:='Daily limit exceeded'; RETURN;
    END IF;

    -- Balance check
    IF p_amount > a_from.balance THEN
        code := 'ERR_NO_FUNDS'; message:='Insufficient funds'; RETURN;
    END IF;

    -- Perform transfer
    UPDATE accounts SET balance=balance - p_amount WHERE account_id=a_from.account_id;
    UPDATE accounts SET balance=balance + p_amount WHERE account_id=a_to.account_id;

    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description,completed_at)
    VALUES (a_from.account_id,a_to.account_id,p_amount,p_currency,rate,amount_kzt,'transfer','completed',p_description,now());

    code := 'OK';
    message := 'Transfer completed';
    RETURN;
END $$;

-- TASK 2: VIEWS

CREATE OR REPLACE VIEW customer_balance_summary AS
SELECT
    c.customer_id,
    c.full_name,
    a.account_number,
    a.currency,
    a.balance,
    (a.balance * (SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY rate_id DESC LIMIT 1)) AS balance_kzt,
    SUM(a.balance * (SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY rate_id DESC LIMIT 1))
        OVER (PARTITION BY c.customer_id) AS total_kzt,
    ROUND(100 * SUM(a.balance * (SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY rate_id DESC LIMIT 1))
        OVER (PARTITION BY c.customer_id) / NULLIF(c.daily_limit_kzt,0),2) AS limit_usage,
    RANK() OVER (ORDER BY SUM(a.balance * (SELECT rate FROM exchange_rates er WHERE er.from_currency=a.currency AND er.to_currency='KZT' ORDER BY rate_id DESC LIMIT 1))
        OVER (PARTITION BY c.customer_id) DESC) AS rank
FROM customers c
LEFT JOIN accounts a ON a.customer_id=c.customer_id;

CREATE OR REPLACE VIEW daily_transaction_report AS
SELECT
    date_trunc('day',created_at) AS day,
    type,
    COUNT(*) AS cnt,
    SUM(amount_kzt) AS total_kzt,
    AVG(amount_kzt) AS avg_kzt,
    SUM(SUM(amount_kzt)) OVER (ORDER BY date_trunc('day',created_at)) AS running_total,
    ROUND(100 * (SUM(amount_kzt) - LAG(SUM(amount_kzt))
        OVER (ORDER BY date_trunc('day',created_at)))
        / NULLIF(LAG(SUM(amount_kzt))
        OVER (ORDER BY date_trunc('day',created_at)),0),2) AS day_growth
FROM transactions
GROUP BY day,type
ORDER BY day DESC;

CREATE OR REPLACE VIEW suspicious_activity_view WITH (security_barrier=true) AS
SELECT
    t.transaction_id,
    t.from_account_id,
    t.to_account_id,
    t.amount,
    t.amount_kzt,
    t.created_at,
    CASE
        WHEN t.amount_kzt > 5000000 THEN 'OVER_5M'
        WHEN EXISTS (
            SELECT 1 FROM transactions t2
            WHERE t2.from_account_id=t.from_account_id
              AND t2.created_at BETWEEN t.created_at - INTERVAL '1 minute' AND t.created_at
        ) THEN 'RAPID_SEQ'
        ELSE NULL
    END AS flag
FROM transactions t
WHERE t.amount_kzt > 5000000
   OR t.transaction_id IN (
       SELECT transaction_id FROM (
           SELECT transaction_id,
                  COUNT(*) OVER (PARTITION BY from_account_id, date_trunc('hour',created_at)) AS hourly_cnt
           FROM transactions
       ) x WHERE x.hourly_cnt > 10
   );

-- TASK 3: INDEXES
CREATE INDEX idx_acc_num_btree ON accounts(account_number);
CREATE INDEX idx_acc_active ON accounts(account_id) WHERE is_active=true;
CREATE INDEX idx_tx_from_time ON transactions(from_account_id,created_at DESC);
CREATE INDEX idx_customers_lower_email ON customers(lower(email));
CREATE INDEX idx_audit_new_gin ON audit_log USING GIN (new_values);
CREATE INDEX idx_customers_iin_hash ON customers USING HASH (iin);
CREATE INDEX idx_tx_covering ON transactions(from_account_id) INCLUDE (amount_kzt,status);

-- TASK 4
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_acc VARCHAR,
    p_payments JSONB
)
RETURNS JSONB LANGUAGE plpgsql AS $$
DECLARE
    comp RECORD;
    pay RECORD;
    v_total NUMERIC := 0;
    v_balance NUMERIC;
    success INT := 0;
    failed INT := 0;
    failed_list JSONB := '[]';
BEGIN
    SELECT * INTO comp FROM accounts WHERE account_number=p_company_acc FOR UPDATE;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('status','ERR_NO_COMPANY');
    END IF;

    -- Sum all payments
    FOR pay IN SELECT * FROM jsonb_to_recordset(p_payments) AS x(iin TEXT, amount NUMERIC, description TEXT)
    LOOP
        v_total := v_total + pay.amount;
    END LOOP;

    SELECT balance INTO v_balance FROM accounts WHERE account_id=comp.account_id;
    IF v_balance < v_total THEN
        RETURN jsonb_build_object('status','ERR_NO_FUNDS','balance',v_balance,'required',v_total);
    END IF;

    -- Process each
    FOR pay IN SELECT * FROM jsonb_to_recordset(p_payments) AS x(iin TEXT, amount NUMERIC, description TEXT)
    LOOP
        BEGIN
            DECLARE
                cid INT;
                acc RECORD;
            BEGIN
                SELECT customer_id INTO cid FROM customers WHERE iin=pay.iin;
                IF NOT FOUND THEN
                    failed := failed + 1;
                    failed_list := failed_list || jsonb_build_object('iin',pay.iin,'reason','Customer not found');
                    CONTINUE;
                END IF;

                SELECT * INTO acc FROM accounts WHERE customer_id=cid AND currency='KZT' AND is_active=true LIMIT 1;
                IF NOT FOUND THEN
                    failed := failed + 1;
                    failed_list := failed_list || jsonb_build_object('iin',pay.iin,'reason','No account');
                    CONTINUE;
                END IF;

                -- Debit company
                UPDATE accounts SET balance=balance - pay.amount WHERE account_id=comp.account_id;

                -- Credit employee
                UPDATE accounts SET balance=balance + pay.amount WHERE account_id=acc.account_id;

                INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description,completed_at)
                VALUES(comp.account_id,acc.account_id,pay.amount,'KZT',1,pay.amount,'salary','completed',pay.description,now());

                success := success + 1;
            END;
        EXCEPTION WHEN OTHERS THEN
            failed := failed + 1;
            failed_list := failed_list || jsonb_build_object('iin',pay.iin,'reason',SQLERRM);
        END;
    END LOOP;

    RETURN jsonb_build_object(
        'status','OK',
        'success',success,
        'failed',failed,
        'details',failed_list
    );
END $$;
-- Materialized view
CREATE MATERIALIZED VIEW salary_batch_summary AS
SELECT
    date_trunc('day',created_at) AS day,
    COUNT(*) FILTER (WHERE type='salary') AS cnt,
    SUM(amount_kzt) FILTER (WHERE type='salary') AS total
FROM transactions
GROUP BY day
ORDER BY day DESC;
COMMIT;
