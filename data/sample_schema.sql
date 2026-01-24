-- SQL Case Studies -- Sample Schema
-- Compatible with PostgreSQL, SQLite, and DuckDB

-- ============================================
-- CUSTOMERS
-- ============================================
CREATE TABLE customers (
    customer_id INTEGER PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    created_at DATE NOT NULL,
    country VARCHAR(50),
    segment VARCHAR(20) -- 'consumer', 'business', 'enterprise'
);

-- ============================================
-- PRODUCTS
-- ============================================
CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price DECIMAL(10, 2) NOT NULL,
    cost DECIMAL(10, 2) NOT NULL
);

-- ============================================
-- ORDERS
-- ============================================
CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL, -- 'pending', 'shipped', 'delivered', 'cancelled'
    total_amount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- ORDER ITEMS
-- ============================================
CREATE TABLE order_items (
    item_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ============================================
-- SUBSCRIPTIONS (for SaaS/recurring revenue)
-- ============================================
CREATE TABLE subscriptions (
    subscription_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    plan_name VARCHAR(50) NOT NULL, -- 'basic', 'pro', 'enterprise'
    monthly_amount DECIMAL(10, 2) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE, -- NULL means active
    status VARCHAR(20) NOT NULL, -- 'active', 'churned', 'paused'
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- EMPLOYEES (for recursive/hierarchy queries)
-- ============================================
CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    manager_id INTEGER, -- self-referencing for hierarchy
    hire_date DATE NOT NULL,
    salary DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- ============================================
-- EVENTS (for user behavior analytics)
-- ============================================
CREATE TABLE events (
    event_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    event_type VARCHAR(50) NOT NULL, -- 'login', 'purchase', 'page_view'
    event_date DATE NOT NULL,
    event_timestamp TIMESTAMP NOT NULL,
    properties TEXT, -- JSON-like string for flexibility
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- SAMPLE DATA
-- ============================================

-- Customers
INSERT INTO customers VALUES
(1, 'alice@example.com', 'Alice', 'Johnson', '2023-01-15', 'USA', 'consumer'),
(2, 'bob@example.com', 'Bob', 'Smith', '2023-02-20', 'UK', 'business'),
(3, 'carol@example.com', 'Carol', 'Williams', '2023-01-10', 'Canada', 'consumer'),
(4, 'david@example.com', 'David', 'Brown', '2023-03-05', 'USA', 'enterprise'),
(5, 'eve@example.com', 'Eve', 'Davis', '2023-04-01', 'Germany', 'business'),
(6, 'frank@example.com', 'Frank', 'Miller', '2023-02-14', 'USA', 'consumer'),
(7, 'grace@example.com', 'Grace', 'Wilson', '2023-05-20', 'UK', 'consumer'),
(8, 'henry@example.com', 'Henry', 'Moore', '2023-06-10', 'Canada', 'business');

-- Products
INSERT INTO products VALUES
(1, 'Laptop Pro', 'Electronics', 1299.99, 899.00),
(2, 'Wireless Mouse', 'Electronics', 49.99, 25.00),
(3, 'USB-C Hub', 'Electronics', 79.99, 35.00),
(4, 'Standing Desk', 'Furniture', 599.99, 350.00),
(5, 'Ergonomic Chair', 'Furniture', 449.99, 280.00),
(6, 'Monitor 27"', 'Electronics', 399.99, 250.00),
(7, 'Keyboard Mechanical', 'Electronics', 149.99, 75.00),
(8, 'Webcam HD', 'Electronics', 89.99, 40.00);

-- Orders
INSERT INTO orders VALUES
(1, 1, '2023-03-01', 'delivered', 1349.98),
(2, 1, '2023-04-15', 'delivered', 79.99),
(3, 2, '2023-03-20', 'delivered', 599.99),
(4, 3, '2023-02-10', 'delivered', 449.99),
(5, 3, '2023-05-01', 'delivered', 149.99),
(6, 4, '2023-04-01', 'delivered', 1699.98),
(7, 5, '2023-05-15', 'shipped', 489.98),
(8, 2, '2023-06-01', 'delivered', 1299.99),
(9, 6, '2023-03-10', 'delivered', 79.99),
(10, 7, '2023-07-01', 'pending', 399.99);

-- Order Items
INSERT INTO order_items VALUES
(1, 1, 1, 1, 1299.99),
(2, 1, 2, 1, 49.99),
(3, 2, 3, 1, 79.99),
(4, 3, 4, 1, 599.99),
(5, 4, 5, 1, 449.99),
(6, 5, 7, 1, 149.99),
(7, 6, 1, 1, 1299.99),
(8, 6, 6, 1, 399.99),
(9, 7, 6, 1, 399.99),
(10, 7, 8, 1, 89.99),
(11, 8, 1, 1, 1299.99),
(12, 9, 3, 1, 79.99),
(13, 10, 6, 1, 399.99);

-- Subscriptions
INSERT INTO subscriptions VALUES
(1, 1, 'pro', 29.99, '2023-03-01', NULL, 'active'),
(2, 2, 'enterprise', 199.99, '2023-03-20', NULL, 'active'),
(3, 3, 'basic', 9.99, '2023-02-10', '2023-06-10', 'churned'),
(4, 4, 'enterprise', 199.99, '2023-04-01', NULL, 'active'),
(5, 5, 'pro', 29.99, '2023-05-15', NULL, 'active'),
(6, 6, 'basic', 9.99, '2023-03-10', NULL, 'active'),
(7, 7, 'pro', 29.99, '2023-07-01', NULL, 'active');

-- Employees (hierarchy: CEO -> VPs -> Managers -> Staff)
INSERT INTO employees VALUES
(1, 'Jane', 'CEO', 'Executive', NULL, '2020-01-01', 250000.00),
(2, 'Tom', 'Chen', 'Engineering', 1, '2020-03-15', 180000.00),
(3, 'Sarah', 'Lee', 'Sales', 1, '2020-02-01', 170000.00),
(4, 'Mike', 'Johnson', 'Engineering', 2, '2021-01-10', 140000.00),
(5, 'Anna', 'Garcia', 'Engineering', 2, '2021-06-01', 135000.00),
(6, 'Chris', 'Wilson', 'Sales', 3, '2021-03-20', 120000.00),
(7, 'Laura', 'Martinez', 'Sales', 3, '2021-07-15', 115000.00),
(8, 'James', 'Taylor', 'Engineering', 4, '2022-02-01', 95000.00),
(9, 'Emma', 'Anderson', 'Engineering', 4, '2022-04-15', 92000.00),
(10, 'Ryan', 'Thomas', 'Sales', 6, '2022-06-01', 75000.00);

-- Events
INSERT INTO events VALUES
(1, 1, 'login', '2023-03-01', '2023-03-01 09:00:00', NULL),
(2, 1, 'purchase', '2023-03-01', '2023-03-01 09:15:00', NULL),
(3, 1, 'login', '2023-03-15', '2023-03-15 10:00:00', NULL),
(4, 1, 'login', '2023-04-01', '2023-04-01 14:00:00', NULL),
(5, 2, 'login', '2023-03-20', '2023-03-20 11:00:00', NULL),
(6, 2, 'purchase', '2023-03-20', '2023-03-20 11:30:00', NULL),
(7, 3, 'login', '2023-02-10', '2023-02-10 16:00:00', NULL),
(8, 3, 'purchase', '2023-02-10', '2023-02-10 16:20:00', NULL),
(9, 4, 'login', '2023-04-01', '2023-04-01 09:00:00', NULL),
(10, 5, 'login', '2023-05-15', '2023-05-15 12:00:00', NULL);
