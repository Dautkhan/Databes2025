CREATE TABLE employees (
    employee_id integer,
    first_name text,
    last_name text,
    age integer CHECK (age BETWEEN 18 AND 65),
    salary numeric CHECK (salary > 0)
);

INSERT INTO employees VALUES (1, 'Alice', 'Ivanova', 30, 3500.00);
INSERT INTO employees VALUES (2, 'Bob', 'Petrov', 65, 5000.50);

CREATE TABLE products_catalog (
    product_id integer,
    product_name text,
    regular_price numeric CHECK (regular_price > 0),
    discount_price numeric CHECK (discount_price > 0),
    CONSTRAINT valid_discount CHECK (discount_price < regular_price)
);

INSERT INTO products_catalog VALUES (10, 'Widget A', 100.00, 80.00);
INSERT INTO products_catalog VALUES (11, 'Widget B', 50.00, 1.00);

CREATE TABLE bookings (
    booking_id integer,
    check_in_date date,
    check_out_date date,
    num_guests integer CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings VALUES (100, '2025-08-01', '2025-08-05', 2);
INSERT INTO bookings VALUES (101, '2025-09-10', '2025-09-12', 1);

CREATE TABLE customers (
    customer_id integer NOT NULL,
    email text NOT NULL,
    phone text,
    registration_date date NOT NULL
);

INSERT INTO customers VALUES (1, 'alice@example.com', '+77000000001', '2025-01-10');
INSERT INTO customers VALUES (2, 'bob@example.com', NULL, '2025-02-20');

CREATE TABLE inventory (
    item_id integer NOT NULL,
    item_name text NOT NULL,
    quantity integer NOT NULL CHECK (quantity >= 0),
    unit_price numeric NOT NULL CHECK (unit_price > 0),
    last_updated timestamp NOT NULL
);

INSERT INTO inventory VALUES (101, 'Screws', 500, 0.05, '2025-04-01 10:00:00');
INSERT INTO inventory VALUES (102, 'Nails', 1000, 0.03, '2025-04-02 11:00:00');

CREATE TABLE users (
    user_id integer,
    username text UNIQUE,
    email text UNIQUE,
    created_at timestamp
);

INSERT INTO users VALUES (1, 'alice', 'alice@mail.com', '2025-05-01 09:00:00');
INSERT INTO users VALUES (2, 'bob', 'bob@mail.com', '2025-05-02 10:00:00');

CREATE TABLE course_enrollments (
    enrollment_id integer,
    student_id integer,
    course_code text,
    semester text,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 1001, 'CS101', '2025-Fall');
INSERT INTO course_enrollments VALUES (2, 1002, 'CS101', '2025-Fall');

CREATE TABLE users_named (
    user_id integer,
    username text,
    email text,
    created_at timestamp,
    CONSTRAINT unique_username UNIQUE (username),
    CONSTRAINT unique_email UNIQUE (email)
);

INSERT INTO users_named VALUES (10, 'dmitry', 'd@ex.com', '2025-06-01 08:00:00');
INSERT INTO users_named VALUES (11, 'emma', 'e@ex.com', '2025-06-02 09:00:00');

CREATE TABLE departments (
    dept_id integer PRIMARY KEY,
    dept_name text NOT NULL,
    location text
);

INSERT INTO departments VALUES (1, 'Sales', 'Almaty');
INSERT INTO departments VALUES (2, 'Engineering', 'Nur-Sultan');
INSERT INTO departments VALUES (3, 'HR', 'Almaty');

CREATE TABLE student_courses (
    student_id integer,
    course_id integer,
    enrollment_date date,
    grade text,
    PRIMARY KEY (student_id, course_id)
);

INSERT INTO student_courses VALUES (2001, 301, '2025-02-01', 'A');
INSERT INTO student_courses VALUES (2002, 301, '2025-02-02', 'B');

CREATE TABLE employees_dept (
    emp_id integer PRIMARY KEY,
    emp_name text NOT NULL,
    dept_id integer REFERENCES departments(dept_id),
    hire_date date
);

INSERT INTO employees_dept VALUES (1000, 'Zhan', 1, '2025-03-15');
INSERT INTO employees_dept VALUES (1001, 'Oleg', 2, '2025-03-20');

CREATE TABLE authors (
    author_id integer PRIMARY KEY,
    author_name text NOT NULL,
    country text
);

CREATE TABLE publishers (
    publisher_id integer PRIMARY KEY,
    publisher_name text NOT NULL,
    city text
);

CREATE TABLE books (
    book_id integer PRIMARY KEY,
    title text NOT NULL,
    author_id integer REFERENCES authors(author_id),
    publisher_id integer REFERENCES publishers(publisher_id),
    publication_year integer,
    isbn text UNIQUE
);

INSERT INTO authors VALUES (1, 'Gabriel Garcia Marquez', 'Colombia');
INSERT INTO authors VALUES (2, 'Fyodor Dostoevsky', 'Russia');

INSERT INTO publishers VALUES (1, 'Penguin Random House', 'London');
INSERT INTO publishers VALUES (2, 'Vintage', 'New York');

INSERT INTO books VALUES (101, 'One Hundred Years of Solitude', 1, 1, 1967, 'ISBN-111-111');
INSERT INTO books VALUES (102, 'Crime and Punishment', 2, 2, 1866, 'ISBN-222-222');

CREATE TABLE categories (
    category_id integer PRIMARY KEY,
    category_name text NOT NULL
);

CREATE TABLE products_fk (
    product_id integer PRIMARY KEY,
    product_name text NOT NULL,
    category_id integer REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    order_date date NOT NULL
);

CREATE TABLE order_items (
    item_id integer PRIMARY KEY,
    order_id integer REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id integer REFERENCES products_fk(product_id),
    quantity integer CHECK (quantity > 0)
);

CREATE TABLE customers_ecom (
    customer_id integer PRIMARY KEY,
    name text NOT NULL,
    email text UNIQUE NOT NULL,
    phone text,
    registration_date date NOT NULL
);

CREATE TABLE products_ecom (
    product_id integer PRIMARY KEY,
    name text NOT NULL,
    description text,
    price numeric CHECK (price >= 0),
    stock_quantity integer CHECK (stock_quantity >= 0)
);

CREATE TABLE orders_ecom (
    order_id integer PRIMARY KEY,
    customer_id integer REFERENCES customers_ecom(customer_id) ON DELETE CASCADE,
    order_date date NOT NULL,
    total_amount numeric CHECK (total_amount >= 0),
    status text CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'))
);

CREATE TABLE order_details_ecom (
    order_detail_id integer PRIMARY KEY,
    order_id integer REFERENCES orders_ecom(order_id) ON DELETE CASCADE,
    product_id integer REFERENCES products_ecom(product_id),
    quantity integer CHECK (quantity > 0),
    unit_price numeric CHECK (unit_price > 0)
);

INSERT INTO customers_ecom VALUES
(1, 'Alice', 'alice@shop.com', '+77001112233', '2025-01-05'),
(2, 'Bob', 'bob@shop.com', '+77002223344', '2025-02-10'),
(3, 'Charlie', 'charlie@shop.com', '+77003334455', '2025-03-15'),
(4, 'Diana', 'diana@shop.com', '+77004445566', '2025-04-20'),
(5, 'Eve', 'eve@shop.com', '+77005556677', '2025-05-25');

INSERT INTO products_ecom VALUES
(1, 'Laptop', '15-inch screen', 350000, 10),
(2, 'Smartphone', 'Android OS', 150000, 25),
(3, 'Headphones', 'Noise Cancelling', 50000, 50),
(4, 'Keyboard', 'Mechanical', 20000, 30),
(5, 'Mouse', 'Wireless', 10000, 40);

INSERT INTO orders_ecom VALUES
(1, 1, '2025-09-10', 400000, 'pending'),
(2, 2, '2025-09-12', 150000, 'processing'),
(3, 3, '2025-09-14', 70000, 'shipped'),
(4, 4, '2025-09-15', 30000, 'delivered'),
(5, 5, '2025-09-16', 10000, 'cancelled');

INSERT INTO order_details_ecom VALUES
(1, 1, 1, 1, 350000),
(2, 1, 3, 1, 50000),
(3, 2, 2, 1, 150000),
(4, 3, 4, 1, 20000),
(5, 3, 5, 1, 10000);
