DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS products CASCADE;


CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10, 2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
    ('Alice', 1000.00),
    ('Bob', 500.00),
    ('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
    ('Joe''s Shop', 'Coke', 2.50),
    ('Joe''s Shop', 'Pepsi', 3.00);

BEGIN
UPTADE accounts SET balance = balance - 100.00
        WHERE name = 'Alice';
UPDATE accounts  SET balance = balance + 100.00
    WHERE name = 'Bob';
COMMIT
SELECT * FROM accounts;

-- Task 3.3
BEGIN
UPDATE accounts SET balance  = balance - 500.00
    WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'ALice';
-- Task 3.4
BEGIN
UPTADE accounts
SET balance = balance - 100
WHERE name = 'Alice';

SAVEPOINT my_savepoint;
UPTADE accounts
SET = balance + 100
WHERE name = 'Bob';

ROLLBACK TO my_savepoint;
UPTADE accounts
SET balance = balance + 100
WHERE name ='Wally';

COMMIT;

SELECT * FROM accounts;
 -- exercises
BEGIN;

DO $$
DECLARE bal DECIMAL;
BEGIN
    SELECT balance INTO bal FROM accounts WHERE name='Bob';
    IF bal < 200 THEN
        RAISE EXCEPTION 'Bob has insufficient funds';
    END IF;
END $$;

UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
UPDATE accounts SET balance = balance + 200 WHERE name='Wally';

COMMIT;

SELECT * FROM accounts;


BEGIN;

INSERT INTO products (shop, product, price)
VALUES ('Joe''s Shop', 'Tea', 2.00);

SAVEPOINT sp1;

UPDATE products SET price = 3.00 WHERE product='Tea';

SAVEPOINT sp2;

DELETE FROM products WHERE product = 'Tea';

ROLLBACK TO sp1;

COMMIT;

SELECT * FROM products;

-- BAD VERSION:
SELECT MAX(price) FROM products WHERE shop='Joe''s Shop';
-- JOE DELETES HIGH PRICE HERE
SELECT MIN(price) FROM products WHERE shop='Joe''s Shop';

-- FIXED VERSION:
BEGIN;
SELECT MAX(price) FROM products WHERE shop='Joe''s Shop';
SELECT MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;

