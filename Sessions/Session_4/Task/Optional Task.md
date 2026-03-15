# Optional Practical Task: Index Design Challenge

**Goal:** Design a small set of indexes (max 3) that will **maximize the overall performance improvement** for a realistic e‑commerce workload, taking into account that some queries are far more frequent than others.

You will have a populated PostgreSQL database to test your ideas.

---

## Context
- You are the database engineer responsible for optimizing this system.
- You are only allowed to add **three new indexes** because indexes increase storage cost and slow down writes.

---

## Database Schema

We use a simplified e‑commerce database. Note that `orders.status` is an **ENUM** type (`order_status`) to restrict values and improve clarity.

```sql
-- ENUM for order status (ensures only valid values)
CREATE TYPE order_status AS ENUM ('pending', 'shipped', 'delivered', 'cancelled');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    status order_status NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    order_date TIMESTAMP DEFAULT NOW(),
    country VARCHAR(50)  -- denormalised for demo
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id),
    product_id INT NOT NULL REFERENCES products(id),
    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL  -- price at order time
);
```

---

## Setup Script

Run the following SQL script to create and populate the database. It includes **baseline indexes on foreign keys** (these are already present). You will add **your own indexes** later.

```sql
-- =========================================
-- INDEX DESIGN CHALLENGE - SETUP SCRIPT
-- =========================================

DROP DATABASE IF EXISTS index_challenge;
CREATE DATABASE index_challenge;
\c index_challenge;

CREATE TYPE order_status AS ENUM ('pending', 'shipped', 'delivered', 'cancelled');

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    country VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO users (email, country, created_at)
SELECT
    'user' || gs || '@example.com',
    (ARRAY['US','UK','EG','DE','FR','IN','BR','CA'])[floor(random()*8)+1],
    NOW() - (random() * interval '3 years')
FROM generate_series(1, 100000) gs;

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category_id INT NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO products (name, category_id, price, created_at)
SELECT
    'Product ' || gs,
    floor(random()*20)+1,
    round((random()*500 + 10)::numeric,2),
    NOW() - (random() * interval '2 years')
FROM generate_series(1, 200000) gs;

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id),
    status order_status NOT NULL,
    total_amount NUMERIC(10,2) NOT NULL,
    order_date TIMESTAMP DEFAULT NOW(),
    country VARCHAR(50)
);

INSERT INTO orders (user_id, status, total_amount, order_date, country)
SELECT
    floor(random()*100000)+1,
    (ARRAY['pending','shipped','delivered','cancelled'])[floor(random()*4)+1]::order_status,
    round((random()*800 + 20)::numeric,2),
    NOW() - (random() * interval '1 year'),
    (ARRAY['US','UK','EG','DE','FR','IN','BR','CA'])[floor(random()*8)+1]
FROM generate_series(1, 500000) gs;

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INT NOT NULL REFERENCES orders(id),
    product_id INT NOT NULL REFERENCES products(id),
    quantity INT NOT NULL,
    price NUMERIC(10,2) NOT NULL
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
    floor(random()*500000)+1,
    floor(random()*200000)+1,
    floor(random()*5)+1,
    round((random()*500 + 10)::numeric,2)
FROM generate_series(1, 1000000) gs;

-- Baseline indexes on foreign keys (already present and must remain). Your task is to add three new indexes on top of them.
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);

-- Update statistics
ANALYZE;
```

After running this script, you will have a database named `index_challenge` with about:
- 100k users
- 200k products
- 500k orders
- 1M order items

This is large enough to make index tuning meaningful, yet small enough to run on a laptop.

---

## 🔍 Workload Queries with Weights

Below are 12 query patterns that represent the most frequent operations in our application. The **weight** column shows the percentage of total queries each pattern represents (based on some application logs). The weights sum to 95%, leaving 5% for other ad‑hoc queries with individual weights less than 0.5% (not listed).

| # | Query Description | Weight |
|---|-------------------|--------|
| 1 | User login / profile lookup by email | 25% |
| 2 | Recent orders for a user (dashboard, top 10) | 20% |
| 3 | Daily sales report (total revenue for a day) | 1% |
| 4 | Pending orders in a specific country (support queue) | 8% |
| 5 | Top‑selling products this month (marketing report) | 2% |
| 6 | List all items in an order (order details page) | 15% |
| 7 | Find orders by date range for a user (user history with filters) | 5% |
| 8 | Count orders per status (dashboard widget) | 3% |
| 9 | Products in a category with price filter (catalog browsing) | 10% |
| 10 | Get a product by ID (product page – already covered by PK) | (ignored) |
| 11 | Monthly order count for the current year (trends chart) | 1% |
| 12 | Orders that are late (pending >7 days) (background job) | 5% |

---

### The Queries (with placeholders for parameters)

**Q1 (25%) – User lookup by email**
```sql
SELECT * FROM users WHERE email = 'someone@example.com';
```

**Q2 (20%) – Recent orders for a user**
```sql
SELECT id, total_amount, order_date 
FROM orders 
WHERE user_id = 12345 
ORDER BY order_date DESC 
LIMIT 10;
```

**Q3 (1%) – Daily sales report**
```sql
SELECT SUM(total_amount) AS revenue
FROM orders
WHERE order_date >= '2024-03-01' AND order_date < '2024-03-02';
```

**Q4 (8%) – Pending orders in a specific country**
```sql
SELECT id, user_id, total_amount
FROM orders
WHERE status = 'pending' AND country = 'EG'
ORDER BY order_date;
```

**Q5 (2%) – Top‑selling products this month**
```sql
SELECT oi.product_id, p.name, SUM(oi.quantity) AS units_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id
WHERE o.order_date >= '2024-03-01' AND o.order_date < '2024-04-01'
GROUP BY oi.product_id, p.name
ORDER BY units_sold DESC
LIMIT 10;
```

**Q6 (15%) – List all items in an order**
```sql
SELECT oi.product_id, p.name, oi.quantity, oi.price
FROM order_items oi
JOIN products p ON oi.product_id = p.id
WHERE oi.order_id = 98765;
```

**Q7 (5%) – Find orders by date range for a user**
```sql
SELECT id, total_amount, order_date
FROM orders
WHERE user_id = 12345
  AND order_date BETWEEN '2024-01-01' AND '2024-01-31';
```

**Q8 (3%) – Count orders per status**
```sql
SELECT status, COUNT(*)
FROM orders
GROUP BY status;
```

**Q9 (10%) – Products in a category with price filter**
```sql
SELECT id, name, price
FROM products
WHERE category_id = 5 AND price BETWEEN 50 AND 100;
```

**Q10 (ignored) – Get a product by ID** (primary key already covers it)
```sql
SELECT * FROM products WHERE id = 42;
```

**Q11 (1%) – Monthly order count for the current year**
```sql
SELECT EXTRACT(MONTH FROM order_date) AS month, COUNT(*)
FROM orders
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'
GROUP BY EXTRACT(MONTH FROM order_date);
```

**Q12 (5%) – Orders that are late (pending >7 days)**
```sql
SELECT id, user_id, order_date
FROM orders
WHERE status = 'pending'
  AND order_date < CURRENT_DATE - INTERVAL '7 days';
```

---

## Your Task

1. **Analyze** each query, paying special attention to the **high‑weight** ones (≥10%): Q1, Q2, Q6, and Q9.
   - Which columns are used in `WHERE`, `JOIN`, `ORDER BY`, `GROUP BY`?
   - Are there range conditions or equality conditions?
   - Could an index make the query an **index‑only scan** or **index scan**?

2. **Propose 3 additional indexes** (beyond the existing foreign‑key indexes) that will give the **best weighted performance improvement** across the workload.
   - Write the `CREATE INDEX` statements.
   - For each index, explain:
     - Which queries it helps (especially high‑weight ones).
     - Why you chose the column order (if composite).
     - Any trade‑offs (e.g., index size, write overhead).
     - How it contributes to reducing the weighted cost.

3. **Test your hypotheses (optional but strongly encouraged):**
   - Run the high‑weight queries before adding your indexes and record their execution plans (`EXPLAIN (ANALYZE, BUFFERS)`).
   - Create your indexes and run the same queries again. Compare the results.
        > Important: Either compare **Warm vs Warm** runs or **Cold vs Cold** runs.
   - Include your observations in your submission.

4. **Bonus Discussion (Optional):**<br/>
The system is growing fast, and the `orders` table is expected to reach 50 million rows within the next year. Would you consider partitioning the table?
If yes, would you choose vertical or horizontal partitioning? Explain why, considering:
    - The table schema (orders has columns of varying sizes and usage patterns).
    - The most frequent query patterns (especially Q2, Q3, Q4, Q7, Q12).
    - Maintenance operations (e.g., archiving old orders).
    - How partitioning might interact with the indexes you proposed.
    > (If you choose horizontal partitioning, you may also mention a specific method (e.g., range by `date`, list by `country`, hash by `user_id`) and why.)

---

## Submission Template

You can submit a short document (text) with the following sections:

```
## Proposed Indexes

1. `CREATE INDEX ... ON ... (...);`
   - **Helps queries:** Q?, Q?, ...
   - **Reasoning:** (explain column order, selectivity, etc.)

2. `CREATE INDEX ...`

...

## Testing Results (Optional)

- Before indexes: (paste EXPLAIN output for Q1, Q2, etc.)  
- After indexes: (paste EXPLAIN output)
- Observations: (what changed, buffer hits/reads, etc.)

## Reflections

- Any trade‑offs you considered?  
- Would you make different choices if you could add 5 indexes?

## Bonus Discussion
...
```
