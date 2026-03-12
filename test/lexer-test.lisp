;;;; cl-chainql lexer tests

(in-package #:cl-chainql.test)

(deftest test-tokenize-simple-select
  (let ((tokens (tokenize "SELECT * FROM blocks")))
    (assert-equal 4 (length tokens))
    (assert-equal :keyword (token-type (first tokens)))
    (assert-equal "SELECT" (token-value (first tokens)))
    (assert-equal :star (token-type (second tokens)))
    (assert-equal :keyword (token-type (third tokens)))
    (assert-equal :identifier (token-type (fourth tokens)))))

(deftest test-tokenize-where-clause
  (let ((tokens (tokenize "SELECT * FROM tx WHERE value > 100")))
    (assert-true (> (length tokens) 6))
    (let ((where-tok (find-if (lambda (tok)
                                (and (eq :keyword (token-type tok))
                                     (string-equal "WHERE" (token-value tok))))
                              tokens)))
      (assert-true where-tok))))

(deftest test-tokenize-string-literal
  (let ((tokens (tokenize "SELECT * FROM tx WHERE addr = 'abc123'")))
    (let ((string-tok (find :string tokens :key #'token-type)))
      (assert-true string-tok)
      (assert-equal "abc123" (token-value string-tok)))))

(deftest test-tokenize-number
  (let ((tokens (tokenize "SELECT * FROM tx LIMIT 100")))
    (let ((num-tok (find :number tokens :key #'token-type)))
      (assert-true num-tok)
      (assert-equal 100 (token-value num-tok)))))

(deftest test-tokenize-operators
  (let ((tokens (tokenize "SELECT * FROM tx WHERE a >= 10 AND b <= 20")))
    (let ((gte-tok (find :gte tokens :key #'token-type))
          (lte-tok (find :lte tokens :key #'token-type)))
      (assert-true gte-tok)
      (assert-true lte-tok))))

(deftest test-tokenize-identifiers
  (let ((tokens (tokenize "SELECT block_height, tx_count FROM blocks")))
    (let ((ids (remove-if-not (lambda (tok) (eq :identifier (token-type tok))) tokens)))
      (assert-equal 3 (length ids))
      (assert-equal "block_height" (token-value (first ids))))))
