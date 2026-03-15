-- Demo 9: Penalty on The Queries that ask for columns from both tables. 
EXPLAIN ANALYZE
SELECT 
    p.id, 
    p.name, 
    p.price, 
    d.warranty_months,
    d.long_description
FROM products p
JOIN product_details d 
  ON p.id = d.product_id
WHERE p.category_id = 5;

-- vs
EXPLAIN ANALYZE
SELECT id, name, price, warranty_months, long_description
FROM products_wide
WHERE p.category_id = 5;
