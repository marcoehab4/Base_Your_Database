-- Demo 2: The Index Impact on Wide Table
-- Context: Show the exact same query on the table after adding the index. It's faster because of the index.


-- Show Existing Indexes for some table
SELECT *
FROM pg_indexes
WHERE tablename = 'products_wide';

-- 1. Create the index live
CREATE INDEX idx_products_category ON products_wide(category_id);

-- 2. Run the query again. The Seq Scan will become an Index Scan.
-- Notice how much faster this is.
EXPLAIN ANALYZE 
SELECT id, name, price 
FROM products_wide 
WHERE category_id = 5;
