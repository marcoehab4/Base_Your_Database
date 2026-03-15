-- Demo 7: Expression Indexes – Solving the Function Trap
-- Objective: Demonstrate how wrapping a column in a function disables a normal index, and how an expression index fixes it.  
-- Context: Use the `users` table with `email` column (already populated).

-- 1. Query by lowercased email (no index):  
EXPLAIN (ANALYZE, BUFFERS) 
SELECT *
FROM users 
WHERE LOWER(email) = 'user12345@example.com';
-- (Seq Scan, because function prevents index use.)

-- 2. Create a standard index on `email`:  
CREATE INDEX idx_users_email ON users(email);

-- 3. Run the same query – still Seq Scan! (Because `LOWER(email)` is not the same as `email`.)
EXPLAIN (ANALYZE, BUFFERS) 
SELECT *
FROM users 
WHERE LOWER(email) = 'user12345@example.com';

-- 4. Create an expression index:  
CREATE INDEX idx_users_lower_email ON users(LOWER(email));

-- 5. Run the query again – now it should use Index Scan.  
EXPLAIN (ANALYZE, BUFFERS) 
SELECT *
FROM users 
WHERE LOWER(email) = 'user12345@example.com';
