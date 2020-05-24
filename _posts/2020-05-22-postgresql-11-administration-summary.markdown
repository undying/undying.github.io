---
layout: post
title: "PostgreSQL 11 Administration Summary"
date: 2020-05-22 09:48:49 +0300
tags: postgresql cheatsheet
---

{% include toc.html %}

---

## Intro
Not so long ago I read a beautiful [book about PostgreSQL 11 Administration](https://www.labirint.ru/books/685536/) and decided to make a summary of interesting for my point of view details.

---

## Locks
### Using CTE with RETURNING

When you need to update record and use result value and don't want to use explicit blocking or long transaction, it's possible to use CTE and UPDATE with RETURNING statement.

**Example:**
```sql
test=# CREATE TABLE t_order (id int PRIMARY KEY);
CREATE TABLE

test=# CREATE TABLE t_room (id int);
CREATE TABLE

test=# INSERT INTO t_room VALUES (0);
INSERT 0

test=# WITH x AS (UPDATE t_room SET id = id + 1 RETURNING *)
        INSERT INTO t_order
        SELECT * FROM x RETURNING *;

 id
____
  1
```

---

### FOR SHARE and FOR UPDATE

To select some data for database, process it and then update this data in database there is a SELECT FOR UPDATE  statement for that.


#### FOR ... clauses by locking strength

The locking clause has general form:

```sql
FOR [lock_strength] [ OF table_name [, ...] ] [ NOWAIT | SKIP LOCKED ]
```

where *lock_strength* can be one of:

- **UPDATE** (when we definitely want to update record, most strong lock)
- **NO KEY UPDATE** (the lock is weaker and can coexist with **SELECT FOR SHARE**)
- **SHARE** (this type lock can be handled by multiple transactions)
- **KEY SHARE** (like **SHARE** lock but weaker. this lock conflicts with **FOR UPDATE** but can coexist with **FOR NO KEY UPDATE**)

See more details [here](https://www.postgresql.org/docs/11/sql-select.html)

---

#### FOR UPDATE SKIP LOCKED

```sql
test=# CREATE TABLE t_room AS
        SELECT * FROM generate_series(1, 200) AS id;
SELECT 200
```

| Transaction 1                                          | Transaction 2                                          |
|--------------------------------------------------------|--------------------------------------------------------|
| `BEGIN;`                                               | `BEGIN;`                                               |
| `SELECT * FROM t_room LIMIT 2 FOR UPDATE SKIP LOCKED;` | `SELECT * FROM t_room LIMIT 2 FOR UPDATE SKIP LOCKED;` |
| # **returns 1, 2**                                     | # **returns 3, 4**                                     |


This only works well if there is no [REFERENCES](https://www.postgresqltutorial.com/postgresql-foreign-key/) in the table. If table have [REFERENCES](https://www.postgresqltutorial.com/postgresql-foreign-key/) second transaction with UPDATE will be blocked till first transaction will end.

---

### Recommended Locks

It's possible to use locks for applications synchronization.
In this case you lock not rows but numbers instead.

| Transaction 1                    | Transaction 2                  |
|----------------------------------|--------------------------------|
| `BEGIN;`                         |                                |
| `SELECT pg_advisory_lock(15);`   |                                |
|                                  | `SELECT pg_advisory_lock(15);` |
|                                  | waiting for lock...            |
|                                  | waiting for lock...            |
| `COMMIT;`                        | waiting for lock...            |
| `SELECT pg_advisory_unlock(15);` | waiting for lock...            |
|                                  |  lock granted!                 |

Handy functions:
 - `pg_advisory_unlock_all()` - unlock all previous locks
 - `pg_try_advisory_lock()` - get lock if possible

 More details in [documentation](https://www.postgresql.org/docs/11/functions-admin.html)

---

## VACUUM
### autovacuum

[Options](https://www.postgresql.org/docs/11/runtime-config-autovacuum.html):
 - **autovacuum_naptime**: Specifies the minimum delay between autovacuum runs on any given database. The delay is measured in seconds, and the default is one minute (1min).
 - **autovacuum_vacuum_threshold**: Specifies the minimum number of updated or deleted tuples needed to trigger a VACUUM in any one table. The default is 50 tuples.
 - **autovacuum_analyze_threshold**: Specifies the minimum number of inserted, updated or deleted tuples needed to trigger an ANALYZE in any one table. The default is 50 tuples.
 - **autovacuum_vacuum_scale_factor**: Specifies a fraction of the table size to add to autovacuum_vacuum_threshold when deciding whether to trigger a VACUUM. The default is 0.2 (20% of table size).
 - **autovacuum_analyze_scale_factor**: Specifies a fraction of the table size to add to autovacuum_analyze_threshold when deciding whether to trigger an ANALYZE. The default is 0.1 (10% of table size).

---

### Transaction ID Wraparound

[Options](https://www.postgresql.org/docs/11/runtime-config-autovacuum.html):
 - **autovacuum_freeze_max_age**: Specifies the maximum age (in transactions) that a table's pg_class.relfrozenxid field can attain before a VACUUM operation is forced to prevent transaction ID wraparound within the table. Note that the system will launch autovacuum processes to prevent wraparound even when autovacuum is otherwise disabled.
 - **autovacuum_multixact_freeze_max_age**: Specifies the maximum age (in multixacts) that a table's pg_class.relminmxid field can attain before a VACUUM operation is forced to prevent multixact ID wraparound within the table. Note that the system will launch autovacuum processes to prevent wraparound even when autovacuum is otherwise disabled.

Wraparound References:
  - https://www.postgresql.org/docs/11/routine-vacuuming.html#VACUUM-FOR-WRAPAROUND
  - https://www.cybertec-postgresql.com/en/autovacuum-wraparound-protection-in-postgresql/

---

### Transaction Duration

**old_snapshot_threshold**: Sets the minimum time that a snapshot can be used without risk of a snapshot too old error occurring when using the snapshot. This parameter can only be set at server start.

Beyond the threshold, old data may be vacuumed away. This can help prevent bloat in the face of snapshots which remain in use for a long time. To prevent incorrect results due to cleanup of data which would otherwise be visible to the snapshot, an error is generated when the snapshot is older than this threshold and the snapshot is used to read a page which has been modified since the snapshot was built. [More details](https://www.postgresql.org/docs/11/runtime-config-resource.html#GUC-OLD-SNAPSHOT-THRESHOLD).

## Indexing
### Costs Model

Costs formula for `Seq Scan`:
```
(blocks to read * seq_page_cost) \
  + (rows scanned * cpu_tuple_cost + rows scanned * cpu_operator_cost)
```

To get sum of block per table:
```sql
SELECT pg_relation_size('table_name') / 8192.0;
```

Useful [options](https://www.postgresql.org/docs/11/runtime-config-query.html):
  - [random_page_cost](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-RANDOM-PAGE-COST): Sets the planner's estimate of the cost of a non-sequentially-fetched disk page. The default is 4.0.
  - [cpu_index_tuple_cost](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-CPU-INDEX-TUPLE-COST): Sets the planner's estimate of the cost of processing each index entry during an index scan. The default is 0.005.

For parallel jobs:
  - [parallel_tuple_cost](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-PARALLEL-TUPLE-COST): Sets the planner's estimate of the cost of transferring one tuple from a parallel worker process to another process. The default is 0.1.
  - [parallel_setup_cost](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-PARALLEL-SETUP-COST): Sets the planner's estimate of the cost of launching parallel worker processes. The default is 1000.
  - [min_parallel_table_scan_size](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-MIN-PARALLEL-TABLE-SCAN-SIZE): Sets the minimum amount of table data that must be scanned in order for a parallel scan to be considered. The default is 8 megabytes (8MB).
  - [min_parallel_index_scan_size](https://www.postgresql.org/docs/11/runtime-config-query.html#GUC-MIN-PARALLEL-INDEX-SCAN-SIZE): Sets the minimum amount of index data that must be scanned in order for a parallel scan to be considered. The default is 512 kilobytes (512kB).

References:
  - https://www.postgresql.org/docs/11/runtime-config-query.html
  - https://www.postgresql.org/docs/11/index-cost-estimation.html



<style>
table{
  border-collapse: collapse;
  border-spacing: 0;
  border:2px solid #000000;
}

th{
  border:2px solid #000000;
}

td{
  border:1px solid #000000;
}
</style>

