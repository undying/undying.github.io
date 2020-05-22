---
layout: post
title: "PostgreSQL 11 Administration Summary"
date: 2020-05-22 09:48:49 +0300
tags: postgresql cheatsheet
---

{% include toc.html %}

## Intro
Not so long ago I've read the [book about PostgreSQL 11 Administration](https://www.labirint.ru/books/685536/) and decided to make a summary of interesting for my point of view details.

## Locks
### Using CTE with RETURNING

When you need to update record and use result value and don't want to use explicit blocking or long transaction, it's possible to use CTE and UPDATE with RETURNING statement.

Example:
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

