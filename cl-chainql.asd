;;;; cl-chainql.asd - SQL-like query language for blockchain data
;;;;
;;;; A standalone Common Lisp library providing SQL-like query capabilities
;;;; for blockchain data structures including UTXOs, transactions, blocks,
;;;; and IP registries.

(asdf:defsystem #:cl-chainql
  :description "SQL-like query language for blockchain data"
  :author "Parkian Company LLC"
  :license "BSD-3-Clause"
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
  :in-order-to ((test-op (test-op #:cl-chainql/test))))

(asdf:defsystem #:cl-chainql/test
  :description "Tests for cl-chainql"
  :depends-on (#:cl-chainql)
  :serial t
  :components ((:module "test"
                :serial t
                :components ((:file "package")
                             (:file "lexer-test")
                             (:file "parser-test")
                             (:file "executor-test"))))
  :perform (test-op (o c)
             (uiop:symbol-call :cl-chainql.test :run-tests)))
