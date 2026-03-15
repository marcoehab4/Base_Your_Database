-- Demo 4: Index‑Only Scan with INCLUDE (PostgreSQL 11+)
-- Objective: Show how a covering index can include extra columns without bloating the key, using `INCLUDE`.  
-- Context: `orders` table with many columns.  

-- 1. Create an index that includes `amount` as a non‑key column:  
CREATE INDEX idx_orders_user_include ON orders(user_id) INCLUDE (amount);

-- 2. Run a query that needs `user_id` and `amount`:  
EXPLAIN ANALYZE
SELECT user_id, amount
FROM orders
WHERE user_id = 12345;

-- Should show Index Only Scan, because both columns are in the index – `user_id` as key, `amount` as included.
