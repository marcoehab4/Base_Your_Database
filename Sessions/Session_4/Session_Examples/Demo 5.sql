-- Demo 5: Partial Indexes in Action
-- Objective: Show that a partial index is tiny, fast for its specific use case, and ignored otherwise.  
-- Context: You already have the `orders` table with a `status` column (values: 'delivered', 'shipped', 'pending', 'cancelled').  

-- 1. Query for pending orders without any index:  
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * 
FROM orders 
WHERE status = 'pending' AND user_id = 12345;
-- (Likely Seq Scan, many rows read.)

-- 2. Create a partial index on `(user_id)` only for pending orders:  
CREATE INDEX idx_orders_pending_user ON orders(user_id) WHERE status = 'pending';

-- 3. Repeat the same query – now it should use the partial index (Index Scan).
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * 
FROM orders 
WHERE status = 'pending' AND user_id = 12345;

-- 4. Query for shipped orders (different status) – show the index is not used.  
EXPLAIN (ANALYZE, BUFFERS) 
SELECT *
FROM orders 
WHERE status = 'shipped' AND user_id = 12345;
-- (Seq Scan or maybe another index if present – note that the partial index is ignored.)
