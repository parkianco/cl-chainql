;;;; cl-chainql - Package Definition
;;;;
;;;; SQL-like query language for blockchain data.
;;;; Supports SELECT, INSERT, UPDATE, DELETE operations.

(defpackage #:cl-chainql
  (:use #:cl)
  (:nicknames #:chainql)
  (:export
   ;; Query parsing
   #:parse-query
   #:parse-select
   #:parse-insert
   #:parse-update
   #:parse-delete
   #:parse-create
   #:query-error

   ;; Lexer/tokenizer
   #:tokenize
   #:token
   #:make-token
   #:token-type
   #:token-value
   #:token-position
   #:token-p

   ;; AST structures
   #:query-ast
   #:query-ast-type
   #:query-ast-components
   #:make-query-ast
   #:query-ast-p

   #:select-clause
   #:select-clause-columns
   #:select-clause-distinct
   #:make-select-clause
   #:select-clause-p

   #:from-clause
   #:from-clause-tables
   #:make-from-clause
   #:from-clause-p

   #:where-clause
   #:where-clause-condition
   #:make-where-clause
   #:where-clause-p

   #:order-clause
   #:order-clause-columns
   #:make-order-clause
   #:order-clause-p

   #:limit-clause
   #:limit-clause-count
   #:limit-clause-offset
   #:make-limit-clause
   #:limit-clause-p

   #:join-clause
   #:join-clause-type
   #:join-clause-table
   #:join-clause-condition
   #:make-join-clause
   #:join-clause-p

   #:group-clause
   #:group-clause-columns
   #:make-group-clause
   #:group-clause-p

   #:having-clause
   #:having-clause-condition
   #:make-having-clause
   #:having-clause-p

   ;; Column and table references
   #:column-ref
   #:column-ref-table
   #:column-ref-name
   #:column-ref-alias
   #:make-column-ref
   #:column-ref-p

   #:table-ref
   #:table-ref-name
   #:table-ref-alias
   #:make-table-ref
   #:table-ref-p

   ;; Expression nodes
   #:expr-binary
   #:expr-binary-op
   #:expr-binary-left
   #:expr-binary-right
   #:make-expr-binary
   #:expr-binary-p

   #:expr-unary
   #:expr-unary-op
   #:expr-unary-arg
   #:make-expr-unary
   #:expr-unary-p

   #:expr-func
   #:expr-func-name
   #:expr-func-args
   #:make-expr-func
   #:expr-func-p

   #:expr-literal
   #:expr-literal-value
   #:expr-literal-type
   #:make-expr-literal
   #:expr-literal-p

   #:expr-subquery
   #:expr-subquery-query
   #:make-expr-subquery
   #:expr-subquery-p

   ;; Query plan
   #:query-plan
   #:query-plan-operations
   #:query-plan-estimated-cost
   #:query-plan-estimated-rows
   #:make-query-plan
   #:query-plan-p

   ;; Execution
   #:execute-query
   #:query-result
   #:query-result-columns
   #:query-result-rows
   #:query-result-row-count
   #:make-query-result
   #:query-result-p
   #:result-set
   #:execute-scan
   #:execute-filter
   #:execute-project
   #:execute-limit
   #:execute-sort

   ;; Optimizer
   #:optimize-query
   #:cost-estimate
   #:build-initial-plan
   #:apply-optimizations
   #:estimate-cost
   #:predicate-pushdown
   #:projection-pushdown

   ;; Data sources
   #:create-datasource
   #:datasource-get
   #:datasource-put

   ;; Views
   #:view-definition
   #:view-definition-name
   #:view-definition-query
   #:view-definition-materialized
   #:view-definition-refresh-interval
   #:make-view-definition
   #:view-definition-p
   #:create-view
   #:drop-view
   #:get-view
   #:refresh-materialized-view
   #:materialized-view
   #:*views*

   ;; Helper functions
   #:keyword-at-p
   #:parse-primary
   #:parse-expression))

(in-package #:cl-chainql)
