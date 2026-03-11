;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-chainql - Query Optimizer
;;;;
;;;; Query plan optimization for ChainQL.

(in-package #:cl-chainql)

(defstruct query-plan
  (operations nil :type list)
  (estimated-cost 0)
  (estimated-rows 0))

(defun optimize-query (ast)
  "Optimize a query AST and return an execution plan."
  (let ((plan (build-initial-plan ast)))
    (setf plan (apply-optimizations plan))
    plan))

(defun build-initial-plan (ast)
  "Build initial execution plan from AST."
  (let ((ops nil))
    (dolist (component (query-ast-components ast))
      (case (car component)
        (:from (push (cons :scan (from-clause-tables (cdr component))) ops))
        (:where (push (cons :filter (where-clause-condition (cdr component))) ops))
        (:select (push (cons :project (select-clause-columns (cdr component))) ops))
        (:order (push (cons :sort (order-clause-columns (cdr component))) ops))
        (:group (push (cons :aggregate (group-clause-columns (cdr component))) ops))
        (:having (push (cons :filter-aggregate (having-clause-condition (cdr component))) ops))
        (:limit (push (cons :limit (limit-clause-count (cdr component))) ops))))
    (make-query-plan :operations (nreverse ops))))

(defun apply-optimizations (plan)
  "Apply optimization passes to a query plan."
  (setf plan (predicate-pushdown plan))
  (setf plan (projection-pushdown plan))
  (estimate-cost plan)
  plan)

(defun predicate-pushdown (plan)
  "Push filter predicates closer to scan operations.
This reduces the amount of data flowing through the pipeline."
  ;; Find scan and filter operations
  (let ((ops (query-plan-operations plan))
        (new-ops nil)
        (pending-filters nil))
    ;; Collect filters and reorder
    (dolist (op ops)
      (case (car op)
        (:filter
         (push op pending-filters))
        (:scan
         ;; Insert filters right after scan
         (push op new-ops)
         (dolist (f (nreverse pending-filters))
           (push f new-ops))
         (setf pending-filters nil))
        (otherwise
         (push op new-ops))))
    ;; Add any remaining filters
    (dolist (f pending-filters)
      (push f new-ops))
    (setf (query-plan-operations plan) (nreverse new-ops)))
  plan)

(defun projection-pushdown (plan)
  "Push projection operations closer to scan operations.
This reduces memory usage by dropping unneeded columns early."
  ;; For now, keep projections where they are
  ;; More sophisticated analysis would track column usage
  plan)

(defun estimate-cost (plan)
  "Estimate the execution cost of a query plan."
  (let ((cost 0)
        (rows 1000))  ; Assume base 1000 rows
    (dolist (op (query-plan-operations plan))
      (case (car op)
        (:scan
         (incf cost (* 10 rows)))  ; I/O cost
        (:filter
         (setf rows (floor rows 10))  ; Assume 10% selectivity
         (incf cost rows))
        (:project
         (incf cost rows))
        (:sort
         (when (> rows 0)
           (incf cost (* rows (max 1 (log rows 2))))))  ; n log n
        (:aggregate
         (setf rows (max 1 (floor rows 100)))  ; Aggregation reduces rows
         (incf cost rows))
        (:limit
         (let ((limit (cdr op)))
           (when limit
             (setf rows (min rows limit)))))))
    (setf (query-plan-estimated-cost plan) (round cost))
    (setf (query-plan-estimated-rows plan) rows))
  plan)

(defun cost-estimate (plan)
  "Get the estimated cost of a plan."
  (query-plan-estimated-cost plan))

;;; Plan analysis utilities

(defun plan-has-scan-p (plan)
  "Check if plan has a scan operation."
  (some (lambda (op) (eq (car op) :scan))
        (query-plan-operations plan)))

(defun plan-tables (plan)
  "Get tables referenced in the plan."
  (loop for op in (query-plan-operations plan)
        when (eq (car op) :scan)
        append (mapcar #'table-ref-name (cdr op))))

(defun plan-columns (plan)
  "Get columns projected in the plan."
  (loop for op in (query-plan-operations plan)
        when (eq (car op) :project)
        append (mapcar #'column-ref-name (cdr op))))
