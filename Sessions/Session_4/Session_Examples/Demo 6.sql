-- NOTE: This demo does not produce a BitmapAnd in PostgreSQL because:
-- 1. PostgreSQL does not have native bitmap indexes; it builds bitmaps on the fly from B‑Tree indexes.
-- 2. The optimizer may decide that using one index and filtering the other condition in memory is cheaper than combining two bitmaps. This is a cost‑based decision, not a bug.

-- Demo 6: The Bitmap Heap Scan (Combining Indexes)
-- Context: Prove that the database is smart enough to use bitwise operations in memory to intersect two indexes before touching the table.

-- 1. Create two separate indexes
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_country ON orders(country);

-- 2. Query both. Students will see 'BitmapAnd' in the execution plan!
EXPLAIN ANALYZE 
SELECT id, total_amount, created_at 
FROM orders 
WHERE status = 'pending' 
  AND country = 'EG';
