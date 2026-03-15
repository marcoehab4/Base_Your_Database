-- DROP DATABASE IF EXISTS ecommerce;

CREATE DATABASE ecommerce
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;


-- =========================================
-- BASIC QUERY OPTIMIZATION DEMO DATABASE BUILDER
-- =========================================

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS product_details;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS products_wide;
DROP TABLE IF EXISTS users;

-- =========================================
-- USERS
-- =========================================

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255),
    country VARCHAR(50),
    signup_date TIMESTAMP,
    is_premium BOOLEAN,
    reputation INT
);

INSERT INTO users (email, country, signup_date, is_premium, reputation)
SELECT
    'user' || gs || '@example.com',
    (ARRAY['US','UK','EG','DE','FR','IN','BR','CA'])[floor(random()*8)+1],
    NOW() - (random() * interval '5 years'),
    random() < 0.1,
    floor(random()*5000)
FROM generate_series(1,100000) gs;

-- =========================================
-- PRODUCTS (VERTICAL PARTITION VERSION)
-- =========================================

CREATE TABLE products (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200),
    category_id INT,
    brand_id INT,
    price NUMERIC(10,2),
    rating NUMERIC(3,2),
    created_at TIMESTAMP,
    is_active BOOLEAN
);

CREATE TABLE product_details (
    product_id BIGINT PRIMARY KEY,
    weight NUMERIC,
    dimensions VARCHAR(100),
    warranty_months INT,
    supplier_id INT,
    manufacturing_country VARCHAR(50),

    -- LARGE COLUMN MOVED OUT
    long_description TEXT
);

-- =========================================
-- WIDE TABLE VERSION (NO PARTITIONING)
-- =========================================

CREATE TABLE products_wide (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200),
    category_id INT,
    brand_id INT,
    price NUMERIC(10,2),
    rating NUMERIC(3,2),
    created_at TIMESTAMP,
    is_active BOOLEAN,

    weight NUMERIC,
    dimensions VARCHAR(100),
    warranty_months INT,
    supplier_id INT,
    manufacturing_country VARCHAR(50),

    -- BIG TEXT COLUMN
    long_description TEXT
);

-- =========================================
-- POPULATE PRODUCTS_WIDE
-- =========================================

INSERT INTO products_wide
SELECT
    gs,
    'Product ' || gs,
    floor(random()*20)+1,
    floor(random()*200)+1,
    round((random()*500)::numeric,2),
    round((random()*5)::numeric,2),
    NOW() - (random() * interval '3 years'),
    random() < 0.95,

    round((random()*10)::numeric,2),
    floor(random()*50) || 'x' || floor(random()*50) || 'x' || floor(random()*50),
    floor(random()*36),
    floor(random()*1000),
    (ARRAY['US','CN','DE','JP','KR'])[floor(random()*5)+1],

    -- BIG DESCRIPTION (~2000 chars)
    repeat(
        'This is a detailed product specification used only occasionally. ',
        30
    )

FROM generate_series(1,500000) gs;

-- =========================================
-- SPLIT DATA INTO VERTICAL PARTITION
-- =========================================

INSERT INTO products
SELECT
    id, name, category_id, brand_id, price, rating, created_at, is_active
FROM products_wide;

INSERT INTO product_details
SELECT
    id,
    weight,
    dimensions,
    warranty_months,
    supplier_id,
    manufacturing_country,
    long_description
FROM products_wide;

-- =========================================
-- ORDERS
-- =========================================

CREATE TABLE orders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT,
    status VARCHAR(20),
    total_amount NUMERIC(10,2),
    payment_method VARCHAR(20),
    country VARCHAR(50),
    created_at TIMESTAMP
);

INSERT INTO orders (user_id, status, total_amount, payment_method, country, created_at)
SELECT
    floor(random()*100000)+1,

    CASE
        WHEN random() < 0.6 THEN 'delivered'
        WHEN random() < 0.8 THEN 'shipped'
        WHEN random() < 0.95 THEN 'pending'
        ELSE 'cancelled'
    END,

    round((random()*800)::numeric,2),

    CASE
        WHEN random() < 0.7 THEN 'card'
        WHEN random() < 0.9 THEN 'paypal'
        ELSE 'bank_transfer'
    END,

    (ARRAY['US','UK','EG','DE','FR','IN','BR','CA'])[floor(random()*8)+1],

    NOW() - (random() * interval '2 years')

FROM generate_series(1,1000000);

-- =========================================
-- ORDER ITEMS
-- =========================================

CREATE TABLE order_items (
    id BIGSERIAL PRIMARY KEY,
    order_id BIGINT,
    product_id BIGINT,
    quantity INT,
    price NUMERIC(10,2)
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
    o.id,
    floor(random()*500000)+1,
    floor(random()*5)+1,
    round((random()*500)::numeric,2)
FROM orders o
JOIN generate_series(1,5) gs
ON random() < 0.5;
