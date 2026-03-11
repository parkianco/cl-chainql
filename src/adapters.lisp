;;;; cl-chainql - Data Source Adapters
;;;;
;;;; Generic adapters for connecting ChainQL to various data sources.

(in-package #:cl-chainql)

;;; Generic data source interface

(defun create-datasource ()
  "Create a new empty data source (hash table)."
  (make-hash-table :test #'equal))

(defun datasource-get (ds table-name)
  "Get table data from a data source."
  (gethash table-name ds))

(defun datasource-put (ds table-name rows)
  "Put table data into a data source."
  (setf (gethash table-name ds) rows))

;;; Convenience functions for building data sources

(defun make-datasource-from-alist (alist)
  "Create a data source from an alist of (table-name . rows) pairs."
  (let ((ds (create-datasource)))
    (dolist (pair alist)
      (datasource-put ds (car pair) (cdr pair)))
    ds))

;;; Row manipulation utilities

(defun make-row (&rest key-value-pairs)
  "Create a row (plist) from key-value pairs.
Example: (make-row :id 1 :name \"Alice\")"
  key-value-pairs)

(defun row-get (row key)
  "Get a value from a row."
  (getf row key))

(defun row-set (row key value)
  "Set a value in a row (returns new row)."
  (let ((new-row (copy-list row)))
    (setf (getf new-row key) value)
    new-row))

;;; Table utilities

(defun table-columns (rows)
  "Get column names from table rows."
  (when rows
    (loop for (key nil) on (first rows) by #'cddr
          collect key)))

(defun table-count (rows)
  "Count rows in a table."
  (length rows))

(defun table-filter (rows predicate)
  "Filter table rows by predicate."
  (remove-if-not predicate rows))

(defun table-sort (rows key-fn &key (test #'<))
  "Sort table rows by key function."
  (sort (copy-list rows) test :key key-fn))

;;; Sample/demo data generation

(defun make-sample-blocks (count)
  "Generate sample block data for testing.
Returns a list of block rows."
  (loop for i from 1 to count
        collect (list :height i
                      :hash (format nil "block-~8,'0X" i)
                      :prev-hash (if (= i 1)
                                     (format nil "~64,'0X" 0)
                                     (format nil "block-~8,'0X" (1- i)))
                      :timestamp (+ 1640000000 (* i 600))
                      :tx-count (+ 1 (random 100))
                      :size (+ 1000 (random 99000)))))

(defun make-sample-transactions (count)
  "Generate sample transaction data for testing.
Returns a list of transaction rows."
  (loop for i from 1 to count
        collect (list :txid (format nil "tx-~8,'0X" i)
                      :block-height (1+ (random 100))
                      :from-address (format nil "addr-~4,'0X" (random 1000))
                      :to-address (format nil "addr-~4,'0X" (random 1000))
                      :value (random 1000000000)
                      :fee (random 100000))))

(defun make-sample-utxos (count)
  "Generate sample UTXO data for testing."
  (loop for i from 1 to count
        collect (list :txid (format nil "tx-~8,'0X" (random 10000))
                      :vout (random 4)
                      :address (format nil "addr-~4,'0X" (random 1000))
                      :value (random 1000000000)
                      :spent nil)))
