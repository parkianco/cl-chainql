# cl-chainql

SQL-like query language for blockchain data in Common Lisp.

## Overview

cl-chainql provides a familiar SQL-like syntax for querying blockchain data structures including blocks, transactions, UTXOs, and more. It includes a complete query processing pipeline: lexer, parser, optimizer, and executor.

## Features

- SQL-like query syntax (SELECT, INSERT, UPDATE, DELETE)
- Query optimization with predicate pushdown
- Cost-based query planning
- Materialized views with automatic refresh
- Extensible data source adapters
- Zero external dependencies (pure Common Lisp)

## Installation

```lisp
(asdf:load-system :cl-chainql)
```

## Quick Start

```lisp
(use-package :cl-chainql)

;; Create a data source
(let ((ds (create-datasource)))
  ;; Add some block data
  (datasource-put ds "blocks"
    (list (list :height 1 :hash "abc" :size 1000)
          (list :height 2 :hash "def" :size 2000)))

  ;; Query it
  (let* ((ast (parse-query "SELECT * FROM blocks WHERE height > 1"))
         (plan (optimize-query ast))
         (result (execute-query plan ds)))
    (result-set result)))
```

## Query Syntax

### SELECT
```sql
SELECT column1, column2 FROM table WHERE condition ORDER BY column LIMIT n
```

### INSERT
```sql
INSERT INTO table (col1, col2) VALUES (val1, val2)
```

### UPDATE
```sql
UPDATE table SET col1 = val1 WHERE condition
```

### DELETE
```sql
DELETE FROM table WHERE condition
```

## Materialized Views

```lisp
;; Create a materialized view
(create-view "recent_blocks"
             "SELECT * FROM blocks ORDER BY height DESC LIMIT 100"
             :materialized t
             :refresh-interval 60)

;; Query the view (uses cache if fresh)
(query-view "recent_blocks" data-source)

;; Force refresh
(refresh-materialized-view "recent_blocks" data-source)
```

## API Reference

### Parsing
- `parse-query` - Parse query string to AST
- `tokenize` - Tokenize query string

### Planning
- `optimize-query` - Optimize AST to execution plan
- `cost-estimate` - Get estimated query cost

### Execution
- `execute-query` - Execute plan against data source
- `result-set` - Get rows from query result

### Data Sources
- `create-datasource` - Create empty data source
- `datasource-get` - Get table from data source
- `datasource-put` - Put table into data source

### Views
- `create-view` - Create view definition
- `drop-view` - Remove view
- `refresh-materialized-view` - Refresh cached data

## Testing

```lisp
(asdf:test-system :cl-chainql)
```

## License

BSD-3-Clause
