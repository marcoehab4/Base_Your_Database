-- Run the query without the index, then create the index, run it again. Compare the EXPLAIN ANALYZE output.
-- - What changed?
-- - Why did the optimizer choose the new plan?
-- - How many buffer hits/reads changed?
EXPLAIN ANALYZE 
SELECT id, name, price 
FROM products_wide 
WHERE category_id = 5 AND price > 50;
