;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: BSD-3-Clause

;;;; cl-chainql - Parser
;;;;
;;;; Parser for ChainQL query language.

(in-package #:cl-chainql)

(define-condition query-error (error)
  ((message :initarg :message :reader query-error-message)
   (position :initarg :position :reader query-error-position :initform nil))
  (:report (lambda (c s)
             (format s "Query error~@[ at position ~A~]: ~A"
                     (query-error-position c)
                     (query-error-message c)))))

(defun parse-query (input)
  "Parse a ChainQL query string and return an AST."
  (let* ((tokens (tokenize input))
         (result (parse-statement tokens)))
    result))

(defun parse-statement (tokens)
  "Parse a statement from token list."
  (let ((first (first tokens)))
    (when (and first (eq (token-type first) :keyword))
      (cond
        ((string-equal (token-value first) "SELECT")
         (make-query-ast :type :select :components (parse-select tokens)))
        ((string-equal (token-value first) "INSERT")
         (make-query-ast :type :insert :components (parse-insert tokens)))
        ((string-equal (token-value first) "UPDATE")
         (make-query-ast :type :update :components (parse-update tokens)))
        ((string-equal (token-value first) "DELETE")
         (make-query-ast :type :delete :components (parse-delete tokens)))
        ((string-equal (token-value first) "CREATE")
         (make-query-ast :type :create :components (parse-create tokens)))))))

(defun keyword-at-p (tokens pos keyword)
  "Check if token at position is a specific keyword."
  (let ((tok (nth pos tokens)))
    (and tok
         (eq (token-type tok) :keyword)
         (string-equal (token-value tok) keyword))))

(defun parse-select (tokens)
  "Parse SELECT query: SELECT columns FROM tables [WHERE cond] [ORDER BY ...] [LIMIT n]"
  (let ((pos 1)
        (components nil))
    ;; Parse SELECT clause
    (multiple-value-bind (select-clause new-pos) (parse-select-list tokens pos)
      (push (cons :select select-clause) components)
      (setf pos new-pos))
    ;; Parse FROM clause
    (when (keyword-at-p tokens pos "FROM")
      (multiple-value-bind (from-clause new-pos) (parse-from tokens (1+ pos))
        (push (cons :from from-clause) components)
        (setf pos new-pos)))
    ;; Parse WHERE clause
    (when (keyword-at-p tokens pos "WHERE")
      (multiple-value-bind (where-clause new-pos) (parse-where tokens (1+ pos))
        (push (cons :where where-clause) components)
        (setf pos new-pos)))
    ;; Parse GROUP BY clause
    (when (keyword-at-p tokens pos "GROUP")
      (multiple-value-bind (group-clause new-pos) (parse-group-by tokens (+ pos 2))
        (push (cons :group group-clause) components)
        (setf pos new-pos)))
    ;; Parse HAVING clause
    (when (keyword-at-p tokens pos "HAVING")
      (multiple-value-bind (having-clause new-pos) (parse-having tokens (1+ pos))
        (push (cons :having having-clause) components)
        (setf pos new-pos)))
    ;; Parse ORDER BY clause
    (when (keyword-at-p tokens pos "ORDER")
      (multiple-value-bind (order-clause new-pos) (parse-order tokens (+ pos 2))
        (push (cons :order order-clause) components)
        (setf pos new-pos)))
    ;; Parse LIMIT clause
    (when (keyword-at-p tokens pos "LIMIT")
      (multiple-value-bind (limit-clause new-pos) (parse-limit tokens (1+ pos))
        (push (cons :limit limit-clause) components)
        (setf pos new-pos)))
    (nreverse components)))

(defun parse-select-list (tokens pos)
  "Parse the column list in a SELECT clause."
  (let ((columns nil))
    (loop for tok = (nth pos tokens)
          while tok
          do (cond
               ((eq (token-type tok) :identifier)
                (push (make-column-ref :name (token-value tok)) columns)
                (incf pos))
               ((eq (token-type tok) :star)
                (push (make-column-ref :name "*") columns)
                (incf pos))
               ((eq (token-type tok) :comma)
                (incf pos))
               ((and (eq (token-type tok) :keyword)
                     (member (token-value tok) '("FROM" "WHERE" "ORDER" "LIMIT" "GROUP" "HAVING")
                             :test #'string-equal))
                (return))
               (t (return))))
    (values (make-select-clause :columns (nreverse columns)) pos)))

(defun parse-from (tokens pos)
  "Parse the FROM clause."
  (let ((tables nil))
    (loop for tok = (nth pos tokens)
          while (and tok (eq (token-type tok) :identifier))
          do (push (make-table-ref :name (token-value tok)) tables)
             (incf pos)
             (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
               (incf pos)))
    (values (make-from-clause :tables (nreverse tables)) pos)))

(defun parse-where (tokens pos)
  "Parse the WHERE clause."
  (let ((condition (parse-expression tokens pos)))
    (values (make-where-clause :condition (car condition)) (cdr condition))))

(defun parse-expression (tokens pos)
  "Parse an expression."
  (parse-or-expression tokens pos))

(defun parse-or-expression (tokens pos)
  "Parse OR expression."
  (let ((left (parse-and-expression tokens pos)))
    (setf pos (cdr left))
    (loop while (keyword-at-p tokens pos "OR")
          do (incf pos)
             (let ((right (parse-and-expression tokens pos)))
               (setf left (cons (make-expr-binary :op :or
                                                  :left (car left)
                                                  :right (car right))
                                (cdr right)))
               (setf pos (cdr right))))
    left))

(defun parse-and-expression (tokens pos)
  "Parse AND expression."
  (let ((left (parse-comparison tokens pos)))
    (setf pos (cdr left))
    (loop while (keyword-at-p tokens pos "AND")
          do (incf pos)
             (let ((right (parse-comparison tokens pos)))
               (setf left (cons (make-expr-binary :op :and
                                                  :left (car left)
                                                  :right (car right))
                                (cdr right)))
               (setf pos (cdr right))))
    left))

(defun parse-comparison (tokens pos)
  "Parse comparison expression."
  (let ((left (parse-primary tokens pos)))
    (setf pos (cdr left))
    (let ((tok (nth pos tokens)))
      (when (and tok (member (token-type tok) '(:eq :neq :lt :gt :lte :gte)))
        (let ((op (token-type tok)))
          (incf pos)
          (let ((right (parse-primary tokens pos)))
            (setf left (cons (make-expr-binary :op op
                                               :left (car left)
                                               :right (car right))
                             (cdr right)))))))
    left))

(defun parse-primary (tokens pos)
  "Parse primary expression (identifier, literal, or parenthesized expression)."
  (let ((tok (nth pos tokens)))
    (cond
      ((null tok)
       (cons nil pos))
      ((eq (token-type tok) :identifier)
       (cons (make-column-ref :name (token-value tok)) (1+ pos)))
      ((eq (token-type tok) :number)
       (cons (make-expr-literal :value (token-value tok) :type :number) (1+ pos)))
      ((eq (token-type tok) :string)
       (cons (make-expr-literal :value (token-value tok) :type :string) (1+ pos)))
      ((eq (token-type tok) :lparen)
       (let ((inner (parse-expression tokens (1+ pos))))
         (cons (car inner) (1+ (cdr inner)))))  ; skip closing paren
      (t (cons nil pos)))))

(defun parse-group-by (tokens pos)
  "Parse GROUP BY clause."
  (let ((columns nil))
    (loop for tok = (nth pos tokens)
          while (and tok (eq (token-type tok) :identifier))
          do (push (make-column-ref :name (token-value tok)) columns)
             (incf pos)
             (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
               (incf pos)))
    (values (make-group-clause :columns (nreverse columns)) pos)))

(defun parse-having (tokens pos)
  "Parse HAVING clause."
  (let ((condition (parse-expression tokens pos)))
    (values (make-having-clause :condition (car condition)) (cdr condition))))

(defun parse-order (tokens pos)
  "Parse ORDER BY clause."
  (let ((columns nil))
    (loop for tok = (nth pos tokens)
          while (and tok (eq (token-type tok) :identifier))
          do (let ((col (make-column-ref :name (token-value tok))))
               (push col columns)
               (incf pos)
               ;; Check for ASC/DESC
               (let ((next (nth pos tokens)))
                 (when (and next (eq (token-type next) :keyword)
                            (member (token-value next) '("ASC" "DESC") :test #'string-equal))
                   (incf pos)))
               (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
                 (incf pos))))
    (values (make-order-clause :columns (nreverse columns)) pos)))

(defun parse-limit (tokens pos)
  "Parse LIMIT clause."
  (let ((tok (nth pos tokens))
        (count nil)
        (offset nil))
    (when (and tok (eq (token-type tok) :number))
      (setf count (token-value tok))
      (incf pos))
    ;; Check for OFFSET
    (when (keyword-at-p tokens pos "OFFSET")
      (incf pos)
      (let ((off-tok (nth pos tokens)))
        (when (and off-tok (eq (token-type off-tok) :number))
          (setf offset (token-value off-tok))
          (incf pos))))
    (values (make-limit-clause :count count :offset offset) pos)))

(defun parse-insert (tokens)
  "Parse INSERT INTO table (col1, col2) VALUES (val1, val2)"
  (let ((pos 1)
        (components nil))
    (unless (keyword-at-p tokens pos "INTO")
      (error 'query-error :message "INSERT requires INTO"))
    (incf pos)
    ;; Table name
    (let ((table-tok (nth pos tokens)))
      (unless (eq (token-type table-tok) :identifier)
        (error 'query-error :message "Expected table name"))
      (push (cons :table (make-table-ref :name (token-value table-tok))) components)
      (incf pos))
    ;; Column list
    (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :lparen))
      (incf pos)
      (let ((columns nil))
        (loop while (and (nth pos tokens) (not (eq (token-type (nth pos tokens)) :rparen)))
              do (let ((col-tok (nth pos tokens)))
                   (when (eq (token-type col-tok) :identifier)
                     (push (make-column-ref :name (token-value col-tok)) columns))
                   (incf pos)
                   (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
                     (incf pos))))
        (push (cons :columns (nreverse columns)) components)
        (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :rparen))
          (incf pos))))
    ;; VALUES
    (unless (keyword-at-p tokens pos "VALUES")
      (error 'query-error :message "INSERT requires VALUES"))
    (incf pos)
    (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :lparen))
      (incf pos)
      (let ((values nil))
        (loop while (and (nth pos tokens) (not (eq (token-type (nth pos tokens)) :rparen)))
              do (let ((val (parse-primary tokens pos)))
                   (push (car val) values)
                   (setf pos (cdr val))
                   (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
                     (incf pos))))
        (push (cons :values (nreverse values)) components)
        (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :rparen))
          (incf pos))))
    (nreverse components)))

(defun parse-update (tokens)
  "Parse UPDATE table SET col1 = val1 WHERE condition"
  (let ((pos 1)
        (components nil))
    ;; Table name
    (let ((table-tok (nth pos tokens)))
      (unless (eq (token-type table-tok) :identifier)
        (error 'query-error :message "Expected table name"))
      (push (cons :table (make-table-ref :name (token-value table-tok))) components)
      (incf pos))
    ;; SET
    (unless (keyword-at-p tokens pos "SET")
      (error 'query-error :message "UPDATE requires SET"))
    (incf pos)
    ;; Assignments
    (let ((assignments nil))
      (loop while (and (nth pos tokens) (not (keyword-at-p tokens pos "WHERE")))
            do (let* ((col-tok (nth pos tokens))
                      (col-name (when (eq (token-type col-tok) :identifier)
                                  (token-value col-tok))))
                 (unless col-name
                   (error 'query-error :message "Expected column name in SET"))
                 (incf pos)
                 (unless (and (nth pos tokens) (eq (token-type (nth pos tokens)) :eq))
                   (error 'query-error :message "Expected = in SET"))
                 (incf pos)
                 (let ((val (parse-primary tokens pos)))
                   (push (make-expr-binary :op :assign
                                           :left (make-column-ref :name col-name)
                                           :right (car val))
                         assignments)
                   (setf pos (cdr val))
                   (when (and (nth pos tokens) (eq (token-type (nth pos tokens)) :comma))
                     (incf pos)))))
      (push (cons :set (nreverse assignments)) components))
    ;; WHERE
    (when (keyword-at-p tokens pos "WHERE")
      (multiple-value-bind (where-clause new-pos) (parse-where tokens (1+ pos))
        (push (cons :where where-clause) components)
        (setf pos new-pos)))
    (nreverse components)))

(defun parse-delete (tokens)
  "Parse DELETE FROM table WHERE condition"
  (let ((pos 1)
        (components nil))
    (unless (keyword-at-p tokens pos "FROM")
      (error 'query-error :message "DELETE requires FROM"))
    (incf pos)
    ;; Table name
    (let ((table-tok (nth pos tokens)))
      (unless (eq (token-type table-tok) :identifier)
        (error 'query-error :message "Expected table name"))
      (push (cons :table (make-table-ref :name (token-value table-tok))) components)
      (incf pos))
    ;; WHERE
    (when (keyword-at-p tokens pos "WHERE")
      (multiple-value-bind (where-clause new-pos) (parse-where tokens (1+ pos))
        (push (cons :where where-clause) components)
        (setf pos new-pos)))
    (nreverse components)))

(defun parse-create (tokens)
  "Parse CREATE statement (stub for extensibility)."
  (declare (ignore tokens))
  nil)
