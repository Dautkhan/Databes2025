-- Task 2.1: Simple B-tree Index
CREATE INDEX emp_salary_idx ON employees(salary);
-- Test
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';
-- There are 2 indexes: emp_id PRIMARY KEY (automatic) and emp_salary_idx


-- Task 2.2: Index on Foreign Keys
CREATE INDEX emp_dept_idx ON employees(dept_id);
-- Test
SELECT * FROM employees WHERE dept_id = 101;
-- Beneficial because foreign keys are often used in JOINs and lookups


-- Task 2.3: View Index Information
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Lists 6 indexes, including automatic ones for PRIMARY KEY and UNIQUE


-- Task 3.1: Multicolumn Index
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);
-- Test
SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;
-- Useful only when filtering by dept_id first, not salary alone


-- Task 3.2: Column Order in Multicolumn Index
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
-- Test
SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;
-- Column order matters: index is most effective when query filters by leading column


-- Task 4.1: Unique Index
ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);
-- Test
INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');
-- ERROR: повторяющееся значение ключа нарушает ограничение уникальности "employees_pkey"


-- Task 4.2: UNIQUE Constraint
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';
-- PostgreSQL automatically creates a unique B-tree index


-- Task 5.1: Index for Sorting
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;
-- Index helps avoid full table sort


-- Task 5.2: Index with NULL Handling
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT project_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- Task 6.1: Function-Based Index
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
-- Without index, PostgreSQL must scan all rows


-- Task 6.2: Index on Calculated Values
ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));
-- Test
SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;


-- Task 7.1: Rename Index
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;
-- Test
SELECT indexname FROM pg_indexes WHERE tablename = 'employees';


-- Task 7.2: Drop Unused Index
DROP INDEX emp_salary_dept_idx;
-- Dropping reduces overhead when index is redundant


-- Task 7.3: Reindex
REINDEX INDEX employees_salary_index;
-- Useful after bulk inserts or index bloat


-- Task 8.1: Optimize Slow Query
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- emp_dept_idx already exists
-- emp_salary_desc_idx already exists

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;


-- Task 8.2: Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;
-- Test
SELECT project_name, budget
FROM projects
WHERE budget > 80000;
-- Advantage: smaller, faster index for frequent subset queries


-- Task 8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000;
-- Output shows Index Scan if index is used, Seq Scan otherwise


-- Task 9.1: Hash Index
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
-- Test
SELECT * FROM departments WHERE dept_name = 'IT';
-- Hash index is good for equality lookups only


-- Task 9.2: Compare Index Types
CREATE INDEX proj_name_btree_idx ON projects(project_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (project_name);
-- Test
SELECT * FROM projects WHERE project_name = 'Website Redesign';
SELECT * FROM projects WHERE project_name > 'Database';
-- Equality works with both, range only with B-tree


-- Task 10.1: Review All Indexes
SELECT schemaname, tablename, indexname,
       pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
-- Largest index usually on columns with many distinct values


-- Task 10.2: Drop Unnecessary Indexes
DROP INDEX IF EXISTS proj_name_hash_idx;


-- Task 10.3: Document Indexes
CREATE VIEW index_documentation AS
SELECT tablename, indexname, indexdef,
       'Improves salary-based queries' AS purpose
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;



-- Questions

-- 1) What is the default index type in PostgreSQL?
-- Answer: B-tree index

-- 2) Name three scenarios where you should create an index:
-- 1. Columns frequently used in WHERE clauses
-- 2. Columns used in JOIN conditions (foreign keys)
-- 3. Columns used in ORDER BY or GROUP BY

-- 3) Name two scenarios where you should NOT create an index:
-- 1. Columns that are rarely queried
-- 2. Small tables where sequential scan is faster

-- 4) What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- Answer: Indexes are automatically updated, which adds overhead to write operations

-- 5) How can you check if a query is using an index?
-- Answer: Use EXPLAIN or EXPLAIN ANALYZE to see if the plan shows "Index Scan"


-- Additional Challenges

-- Challenge 1: Index for employees hired in a specific month
CREATE INDEX emp_hire_month_idx ON employees(EXTRACT(MONTH FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(MONTH FROM hire_date) = 6;


-- Challenge 2: Composite Unique Index on dept_id and email
CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);


-- Challenge 3: Compare query performance with and without indexes
EXPLAIN ANALYZE SELECT * FROM employees WHERE salary > 52000;


-- Challenge 4: Covering Index (includes all needed columns)
CREATE INDEX emp_covering_idx ON employees(dept_id) INCLUDE (emp_name, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101;