# T3 — SQL Query Optimization

## Task
Optimize a slow dashboard query:

```sql
-- Slow query (N+1 problem, missing indexes)
SELECT u.*,
  (SELECT COUNT(*) FROM orders WHERE user_id = u.id) as order_count,
  (SELECT SUM(total) FROM orders WHERE user_id = u.id) as total_spent
FROM users u
WHERE u.created_at > '2024-01-01'
ORDER BY total_spent DESC
LIMIT 20;
```

Requirements:
- Rewrite as single JOIN query
- Add appropriate indexes
- Add query execution plan analysis
- Target: <100ms on 1M row table

Target stack: PostgreSQL + Prisma ORM

## Measurement
- Token usage: input + output
- Query correctness: yes/no (same results)
- Index suggestion quality: count of useful indexes
- Parameterized query: yes/no

## Success Criteria
- Single query (no subqueries or N+1)
- All inputs parameterized
- At least 2 indexes suggested
- Prisma migration file generated
