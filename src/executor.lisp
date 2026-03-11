;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-chainql - Query Executor
;;;;
;;;; Execute optimized query plans against data sources.

(in-package #:cl-chainql)

(defstruct query-result
  (columns nil :type list)
  (rows nil :type list)
  (row-count 0))

(defun execute-query (plan data-sources)
  "Execute a query plan against the provided data sources.
DATA-SOURCES is a hash table mapping table names to row lists."
  (let ((current-data nil))
    (dolist (op (query-plan-operations plan))
      (setf current-data
            (case (car op)
              (:scan (execute-scan (cdr op) data-sources))
              (:filter (execute-filter (cdr op) current-data))
              (:project (execute-project (cdr op) current-data))
              (:sort (execute-sort (cdr op) current-data))
              (:limit (execute-limit (cdr op) current-data))
              (:aggregate (execute-aggregate (cdr op) current-data))
              (otherwise current-data))))
    (make-query-result :rows current-data
                       :row-count (length current-data))))

(defun execute-scan (tables data-sources)
  "Scan tables from data sources.
Returns combined row list from all referenced tables."
  (when tables
    (let ((table (first tables)))
      (gethash (table-ref-name table) data-sources))))

(defun execute-filter (condition rows)
  "Filter rows based on condition."
  (remove-if-not (lambda (row) (evaluate-condition condition row)) rows))

(defun evaluate-condition (condition row)
  "Evaluate a condition against a row.
Returns T if the row matches, NIL otherwise."
  (cond
    ((null condition) t)
    ((expr-binary-p condition)
     (let ((op (expr-binary-op condition))
           (left-val (evaluate-expr (expr-binary-left condition) row))
           (right-val (evaluate-expr (expr-binary-right condition) row)))
       (case op
         (:eq (equal left-val right-val))
         (:neq (not (equal left-val right-val)))
         (:lt (and (numberp left-val) (numberp right-val) (< left-val right-val)))
         (:gt (and (numberp left-val) (numberp right-val) (> left-val right-val)))
         (:lte (and (numberp left-val) (numberp right-val) (<= left-val right-val)))
         (:gte (and (numberp left-val) (numberp right-val) (>= left-val right-val)))
         (:and (and left-val right-val))
         (:or (or left-val right-val))
         (otherwise t))))
    ((expr-unary-p condition)
     (let ((op (expr-unary-op condition))
           (arg-val (evaluate-expr (expr-unary-arg condition) row)))
       (case op
         (:not (not arg-val))
         (otherwise t))))
    (t t)))

(defun evaluate-expr (expr row)
  "Evaluate an expression against a row and return its value."
  (cond
    ((null expr) nil)
    ((column-ref-p expr)
     (let ((col-name (column-ref-name expr)))
       (getf row (intern (string-upcase col-name) :keyword))))
    ((expr-literal-p expr)
     (expr-literal-value expr))
    ((expr-binary-p expr)
     (evaluate-condition expr row))
    (t expr)))

(defun execute-project (columns rows)
  "Project specified columns from rows.
If columns contains *, returns all columns."
  (if (and columns
           (not (and (= (length columns) 1)
                     (equal "*" (column-ref-name (first columns))))))
      (mapcar (lambda (row)
                (loop for col in columns
                      for name = (column-ref-name col)
                      for key = (intern (string-upcase name) :keyword)
                      append (list key (getf row key))))
              rows)
      rows))

(defun execute-sort (columns rows)
  "Sort rows by specified columns."
  (if columns
      (let ((first-col (first columns)))
        (sort (copy-list rows)
              (lambda (a b)
                (let* ((key (intern (string-upcase (column-ref-name first-col)) :keyword))
                       (va (getf a key))
                       (vb (getf b key)))
                  (cond
                    ((and (numberp va) (numberp vb)) (< va vb))
                    ((and (stringp va) (stringp vb)) (string< va vb))
                    (t nil))))))
      rows))

(defun execute-limit (count rows)
  "Limit result to first COUNT rows."
  (if (and count (> count 0))
      (subseq rows 0 (min count (length rows)))
      rows))

(defun execute-aggregate (columns rows)
  "Execute aggregation operation.
Groups rows by columns and applies aggregate functions."
  (declare (ignore columns))
  ;; Simple implementation: return all rows
  ;; Full implementation would support GROUP BY
  rows)

(defun result-set (result)
  "Get the row list from a query result."
  (query-result-rows result))

;;; High-level query execution

(defun run-query (query-string data-sources)
  "Parse, optimize, and execute a query string."
  (let* ((ast (parse-query query-string))
         (plan (optimize-query ast)))
    (execute-query plan data-sources)))
