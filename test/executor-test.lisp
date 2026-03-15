;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

;;;; cl-chainql executor tests

(in-package #:cl-chainql.test)

(defun make-test-datasource ()
  "Create a test data source with sample data."
  (let ((ds (create-datasource)))
    (datasource-put ds "blocks"
                    (list (list :height 1 :hash "aaa" :size 1000)
                          (list :height 2 :hash "bbb" :size 2000)
                          (list :height 3 :hash "ccc" :size 3000)
                          (list :height 4 :hash "ddd" :size 4000)
                          (list :height 5 :hash "eee" :size 5000)))
    (datasource-put ds "transactions"
                    (list (list :txid "tx1" :value 100 :block 1)
                          (list :txid "tx2" :value 200 :block 1)
                          (list :txid "tx3" :value 300 :block 2)))
    ds))

(deftest test-execute-select-all
  (let* ((ds (make-test-datasource))
         (ast (parse-query "SELECT * FROM blocks"))
         (plan (optimize-query ast))
         (result (execute-query plan ds)))
    (assert-true result)
    (assert-equal 5 (query-result-row-count result))))

(deftest test-execute-with-limit
  (let* ((ds (make-test-datasource))
         (ast (parse-query "SELECT * FROM blocks LIMIT 2"))
         (plan (optimize-query ast))
         (result (execute-query plan ds)))
    (assert-equal 2 (query-result-row-count result))))

(deftest test-execute-with-where
  (let* ((ds (make-test-datasource))
         (ast (parse-query "SELECT * FROM blocks WHERE height > 3"))
         (plan (optimize-query ast))
         (result (execute-query plan ds)))
    ;; Should return blocks 4 and 5
    (assert-equal 2 (query-result-row-count result))))

(deftest test-execute-projection
  (let* ((ds (make-test-datasource))
         (ast (parse-query "SELECT height FROM blocks"))
         (plan (optimize-query ast))
         (result (execute-query plan ds))
         (rows (result-set result)))
    (assert-equal 5 (length rows))
    ;; Each row should only have :height
    (dolist (row rows)
      (assert-true (getf row :height))
      (assert-nil (getf row :hash)))))

(deftest test-execute-sort
  (let* ((ds (make-test-datasource))
         (ast (parse-query "SELECT * FROM blocks ORDER BY height"))
         (plan (optimize-query ast))
         (result (execute-query plan ds))
         (rows (result-set result)))
    (assert-equal 1 (getf (first rows) :height))
    (assert-equal 5 (getf (fifth rows) :height))))

(deftest test-optimizer-generates-plan
  (let* ((ast (parse-query "SELECT * FROM blocks WHERE height > 10 ORDER BY height LIMIT 5"))
         (plan (optimize-query ast)))
    (assert-true plan)
    (assert-true (query-plan-operations plan))
    (assert-true (> (query-plan-estimated-cost plan) 0))))

(deftest test-datasource-operations
  (let ((ds (create-datasource)))
    (datasource-put ds "test" (list (list :id 1)))
    (let ((data (datasource-get ds "test")))
      (assert-true data)
      (assert-equal 1 (length data)))))
