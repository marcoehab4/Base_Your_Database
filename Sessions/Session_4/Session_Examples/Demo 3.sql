-- Demo 3: The Holy Grail (Index-Only Scan, Composite Covering Index)
-- Context: Show what happens when the index has all the answers and the database doesn't even touch the main table.

-- 1. Create an index on both user_id and amount
CREATE INDEX idx_orders_covering ON orders(user_id, total_amount);

-- 2. Select ONLY the columns that are inside the index
EXPLAIN ANALYZE 
SELECT user_id, total_amount
FROM orders 
WHERE user_id = 12345;
