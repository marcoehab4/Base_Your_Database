-- Demo 8: The Vertical Partitioning Win (Sequential Scan)
-- Context: Show the exact same query on the partitioned table. It's still a Seq Scan, but it's much faster because the rows are narrower and more fit into a single memory page.

-- Notice how much faster this is even without index!
EXPLAIN ANALYZE
SELECT id, name, price 
FROM products
WHERE category_id = 5;
