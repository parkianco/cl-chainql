;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

;;;; cl-chainql parser tests

(in-package #:cl-chainql.test)

(deftest test-parse-simple-select
  (let ((ast (parse-query "SELECT * FROM blocks")))
    (assert-true ast)
    (assert-equal :select (query-ast-type ast))
    (let ((components (query-ast-components ast)))
      (assert-true (assoc :select components))
      (assert-true (assoc :from components)))))

(deftest test-parse-select-columns
  (let ((ast (parse-query "SELECT height, hash FROM blocks")))
    (let* ((components (query-ast-components ast))
           (select (cdr (assoc :select components)))
           (columns (select-clause-columns select)))
      (assert-equal 2 (length columns))
      (assert-equal "height" (column-ref-name (first columns)))
      (assert-equal "hash" (column-ref-name (second columns))))))

(deftest test-parse-where
  (let ((ast (parse-query "SELECT * FROM blocks WHERE height > 100")))
    (let* ((components (query-ast-components ast))
           (where (cdr (assoc :where components))))
      (assert-true where)
      (assert-true (where-clause-condition where)))))

(deftest test-parse-limit
  (let ((ast (parse-query "SELECT * FROM blocks LIMIT 10")))
    (let* ((components (query-ast-components ast))
           (limit (cdr (assoc :limit components))))
      (assert-true limit)
      (assert-equal 10 (limit-clause-count limit)))))

(deftest test-parse-order-by
  (let ((ast (parse-query "SELECT * FROM blocks ORDER BY height")))
    (let* ((components (query-ast-components ast))
           (order (cdr (assoc :order components))))
      (assert-true order)
      (assert-true (order-clause-columns order)))))

(deftest test-parse-insert
  (let ((ast (parse-query "INSERT INTO blocks (height, hash) VALUES (1, 'abc')")))
    (assert-true ast)
    (assert-equal :insert (query-ast-type ast))))

(deftest test-parse-update
  (let ((ast (parse-query "UPDATE blocks SET height = 100 WHERE hash = 'abc'")))
    (assert-true ast)
    (assert-equal :update (query-ast-type ast))))

(deftest test-parse-delete
  (let ((ast (parse-query "DELETE FROM blocks WHERE height < 10")))
    (assert-true ast)
    (assert-equal :delete (query-ast-type ast))))
