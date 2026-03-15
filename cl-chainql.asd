;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-chainql.asd - SQL-like query language for blockchain data
;;;;
;;;; A standalone Common Lisp library providing SQL-like query capabilities
;;;; for blockchain data structures including UTXOs, transactions, blocks,
;;;; and IP registries.

(asdf:defsystem #:cl-chainql
  :description "SQL-like query language for blockchain data"
  :author "Parkian Company LLC"
  :license "Apache-2.0"
  :version "0.1.0"
  :serial t
  :depends-on ()
  :components ((:file "package")
               (:module "src"
                :serial t
                :components ((:file "ast")
                             (:file "lexer")
                             (:file "parser")
                             (:file "optimizer")
                             (:file "executor")
                             (:file "views")
                             (:file "adapters"))))
  :in-order-to ((asdf:test-op (test-op #:cl-chainql/test))))

(asdf:defsystem #:cl-chainql/test
  :description "Tests for cl-chainql"
  :depends-on (#:cl-chainql)
  :serial t
  :components ((:module "test"
                :serial t
                :components ((:file "package")
                             (:file "executor-test")
                             (:file "parser-test")
                             (:file "executor-test"))))
  :perform (asdf:test-op (o c)
             (let ((result (uiop:symbol-call :cl-chainql.test :run-tests)))
               (unless result
                 (error "Tests failed")))))
