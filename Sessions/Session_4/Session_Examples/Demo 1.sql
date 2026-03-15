-- Demo 1: The "Wide Table" Penalty (Sequential Scan)
-- Context: Show how scanning a table with massive, unused text columns hurts performance because the database has to load heavy pages into memory.

-- Watch this take a long time and do a full Seq Scan
EXPLAIN ANALYZE 
SELECT id, name, price 
FROM products_wide 
WHERE category_id = 5;

-- Related to Demo 8 & Demo 9
