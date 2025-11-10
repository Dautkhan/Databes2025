-- part clean
DROP MATERIALIZED VIEW IF EXISTS dept_summary_mv CASCADE;
DROP MATERIALIZED VIEW IF EXISTS project_stats_mv CASCADE;
DROP VIEW IF EXISTS dept_dashboard CASCADE;
DROP VIEW IF EXISTS high_budget_projects CASCADE;
DROP VIEW IF EXISTS finance_employee_view CASCADE;
DROP VIEW IF EXISTS hr_employee_view CASCADE;
DROP VIEW IF EXISTS employee_salaries CASCADE;
DROP VIEW IF EXISTS temp_view CASCADE;
DROP VIEW IF EXISTS top_performers CASCADE;
DROP VIEW IF EXISTS high_earners CASCADE;
DROP VIEW IF EXISTS project_overview CASCADE;
DROP VIEW IF EXISTS dept_statistics CASCADE;
DROP VIEW IF EXISTS employee_details CASCADE;

DROP TABLE IF EXISTS employee_projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;



-- Part 1

CREATE TABLE departments (
  dept_id   INT PRIMARY KEY,
  dept_name TEXT NOT NULL,
  location  TEXT
);

CREATE TABLE employees (
  emp_id   INT PRIMARY KEY,
  emp_name TEXT NOT NULL,
  dept_id  INT REFERENCES departments(dept_id),
  salary   NUMERIC(12,2)
);

CREATE TABLE projects (
  project_id INT PRIMARY KEY,
  project_name TEXT NOT NULL,
  dept_id INT REFERENCES departments(dept_id),
  budget NUMERIC(14,2),
  created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Many-to-many: employees assigned to projects
CREATE TABLE employee_projects (
  emp_id INT REFERENCES employees(emp_id),
  project_id INT REFERENCES projects(project_id),
  PRIMARY KEY (emp_id, project_id)
);


INSERT INTO departments (dept_id, dept_name, location) VALUES
 (101, 'IT', 'Almaty'),
 (102, 'HR', 'Nur-Sultan'),
 (103, 'Finance', 'Almaty'),
 (104, 'R&D', 'Shymkent');

INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES
 (1, 'John Smith', 101, 50000),
 (2, 'Jane Doe', 101, 65000),
 (3, 'Emily Davis', 102, 48000),
 (4, 'Michael Lee', 103, 72000),
 (5, 'Tom Brown', NULL, 55000) ; -- Tom has no department

INSERT INTO projects (project_id, project_name, dept_id, budget) VALUES
 (1001, 'Alpha', 101, 120000),
 (1002, 'Beta', 103, 80000),
 (1003, 'Gamma', 104, 40000);

INSERT INTO employee_projects (emp_id, project_id) VALUES
 (1, 1001),
 (2, 1001),
 (4, 1002);


-- Part 2: Creating Basic Views


CREATE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_id, d.dept_name, d.location
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;  -- inner join: only employees WITH a department


CREATE VIEW dept_statistics AS
SELECT d.dept_id, d.dept_name,
       COUNT(e.emp_id) AS employee_count,
       COALESCE(ROUND(AVG(e.salary)::numeric, 2), 0) AS avg_salary,
       COALESCE(MAX(e.salary), 0) AS max_salary,
       COALESCE(MIN(e.salary), 0) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;


CREATE VIEW project_overview AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name, d.location,
       (SELECT COUNT(*) FROM employees e WHERE e.dept_id = d.dept_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id;


CREATE VIEW high_earners AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;

-- Part 3


CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_id, e.emp_name, e.salary, d.dept_id, d.dept_name, d.location,
       CASE
         WHEN e.salary > 60000 THEN 'High'
         WHEN e.salary > 50000 THEN 'Medium'
         ELSE 'Standard'
       END AS salary_grade
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id;


ALTER VIEW high_earners RENAME TO top_performers;



CREATE VIEW temp_view AS
SELECT emp_id, emp_name, salary FROM employees WHERE salary < 50000;

DROP VIEW IF EXISTS temp_view;


-- Part 4


CREATE VIEW employee_salaries AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees;

UPDATE employee_salaries SET salary = 52000 WHERE emp_name = 'John Smith';

INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary) VALUES (6, 'Alice Johnson', 102, 58000);

CREATE VIEW it_employees AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;

-- Part 5

CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id, d.dept_name,
       COUNT(e.emp_id) AS total_employees,
       COALESCE(SUM(e.salary), 0) AS total_salaries,
       (SELECT COUNT(*) FROM projects p WHERE p.dept_id = d.dept_id) AS total_projects,
       COALESCE((SELECT SUM(p.budget) FROM projects p WHERE p.dept_id = d.dept_id), 0) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;



INSERT INTO employees (emp_id, emp_name, dept_id, salary) VALUES (8, 'Charlie Brown', 101, 54000);

REFRESH MATERIALIZED VIEW dept_summary_mv;

CREATE UNIQUE INDEX IF NOT EXISTS idx_dept_summary_mv_dept_id ON dept_summary_mv(dept_id);

CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name,
       (SELECT COUNT(*) FROM employee_projects ep WHERE ep.project_id = p.project_id) AS assigned_count
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WITH NO DATA;


-- Part 6: Database Roles




CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user LOGIN PASSWORD 'report456';


CREATE ROLE db_creator LOGIN PASSWORD 'creator789' CREATEDB;
CREATE ROLE user_manager LOGIN PASSWORD 'manager101' CREATEROLE;

GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;


CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team NOLOGIN;

CREATE ROLE hr_user1 LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 LOGIN PASSWORD 'fin001';


GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;


GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

REVOKE UPDATE ON employees FROM hr_team;

REVOKE hr_team FROM hr_user2;

REVOKE ALL ON employee_details FROM data_viewer;


ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';

ALTER ROLE analyst WITH PASSWORD NULL;

ALTER ROLE data_viewer WITH CONNECTION LIMIT 5;


CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';


GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;


GRANT INSERT, UPDATE ON employees TO senior_analyst;


CREATE ROLE project_manager LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;


REASSIGN OWNED BY temp_owner TO postgres;

DROP OWNED BY temp_owner;

DROP ROLE temp_owner;


CREATE VIEW hr_employee_view AS
SELECT emp_id, emp_name, dept_id, salary
FROM employees
WHERE dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- Part 8


CREATE VIEW dept_dashboard AS
SELECT d.dept_id, d.dept_name, d.location,
       COUNT(e.emp_id) AS employee_count,
       ROUND(COALESCE(AVG(e.salary),0)::numeric, 2) AS avg_salary,
       (SELECT COUNT(*) FROM projects p WHERE p.dept_id = d.dept_id) AS active_projects,
       COALESCE((SELECT SUM(p.budget) FROM projects p WHERE p.dept_id = d.dept_id), 0) AS total_project_budget,
       ROUND(
         CASE WHEN COUNT(e.emp_id) = 0 THEN 0
              ELSE (COALESCE((SELECT SUM(p.budget) FROM projects p WHERE p.dept_id = d.dept_id),0) / NULLIF(COUNT(e.emp_id),0))
         END
       ::numeric, 2) AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;


ALTER TABLE projects ADD COLUMN IF NOT EXISTS created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name, p.created_date,
       CASE
         WHEN p.budget > 150000 THEN 'Critical Review Required'
         WHEN p.budget > 100000 THEN 'Management Approval Needed'
         ELSE 'Standard Process'
       END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;


CREATE ROLE viewer_role NOLOGIN;
CREATE ROLE entry_role NOLOGIN;
CREATE ROLE analyst_role NOLOGIN;
CREATE ROLE manager_role NOLOGIN;


GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;


GRANT viewer_role TO entry_role;
GRANT entry_role TO analyst_role;
GRANT analyst_role TO manager_role;

GRANT INSERT ON employees, projects TO entry_role;
GRANT UPDATE ON employees, projects TO analyst_role;
GRANT DELETE ON employees, projects TO manager_role;


CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;

----