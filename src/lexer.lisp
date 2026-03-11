;;;; cl-chainql - Lexer
;;;;
;;;; Tokenizer for ChainQL query language.

(in-package #:cl-chainql)

(defstruct token
  (type nil :type keyword)
  (value nil)
  (position 0 :type integer))

(defvar *keywords*
  '("SELECT" "FROM" "WHERE" "AND" "OR" "NOT" "ORDER" "BY" "ASC" "DESC"
    "LIMIT" "OFFSET" "JOIN" "ON" "LEFT" "RIGHT" "INNER" "GROUP" "HAVING"
    "INSERT" "INTO" "VALUES" "UPDATE" "SET" "DELETE" "CREATE" "VIEW" "AS"
    "NULL" "IS" "IN" "BETWEEN" "LIKE" "EXISTS" "DISTINCT" "ALL" "ANY"
    "COUNT" "SUM" "AVG" "MIN" "MAX"))

(defun tokenize (input)
  "Tokenize a ChainQL query string into a list of tokens."
  (let ((tokens nil)
        (pos 0)
        (len (length input)))
    (loop while (< pos len)
          for char = (char input pos)
          do (cond
               ((whitespace-p char)
                (incf pos))
               ((alpha-char-p char)
                (multiple-value-bind (tok end) (read-identifier input pos)
                  (push tok tokens)
                  (setf pos end)))
               ((digit-char-p char)
                (multiple-value-bind (tok end) (read-number input pos)
                  (push tok tokens)
                  (setf pos end)))
               ((char= char #\')
                (multiple-value-bind (tok end) (read-string input pos)
                  (push tok tokens)
                  (setf pos end)))
               ((member char '(#\= #\< #\> #\! #\+ #\- #\* #\/))
                (multiple-value-bind (tok end) (read-operator input pos)
                  (push tok tokens)
                  (setf pos end)))
               ((member char '(#\( #\) #\, #\; #\.))
                (push (make-token :type (case char
                                          (#\( :lparen)
                                          (#\) :rparen)
                                          (#\, :comma)
                                          (#\; :semicolon)
                                          (#\. :dot))
                                  :value (string char)
                                  :position pos)
                      tokens)
                (incf pos))
               (t (incf pos))))
    (nreverse tokens)))

(defun whitespace-p (char)
  "Check if character is whitespace."
  (member char '(#\Space #\Tab #\Newline #\Return)))

(defun read-identifier (input pos)
  "Read an identifier or keyword from input starting at pos."
  (let ((end pos))
    (loop while (and (< end (length input))
                     (or (alphanumericp (char input end))
                         (char= (char input end) #\_)))
          do (incf end))
    (let ((str (subseq input pos end)))
      (values (make-token :type (if (member (string-upcase str) *keywords* :test #'string=)
                                    :keyword
                                    :identifier)
                          :value str
                          :position pos)
              end))))

(defun read-number (input pos)
  "Read a number from input starting at pos."
  (let ((end pos)
        (has-dot nil))
    (loop while (and (< end (length input))
                     (or (digit-char-p (char input end))
                         (and (char= (char input end) #\.) (not has-dot))))
          do (when (char= (char input end) #\.)
               (setf has-dot t))
             (incf end))
    (values (make-token :type :number
                        :value (parse-number-value (subseq input pos end))
                        :position pos)
            end)))

(defun parse-number-value (str)
  "Parse a number string into a numeric value."
  (if (find #\. str)
      (parse-float-value str)
      (parse-integer str)))

(defun parse-float-value (str)
  "Parse a floating-point number from string."
  (read-from-string str))

(defun read-string (input pos)
  "Read a quoted string from input starting at pos."
  (let ((end (1+ pos)))
    (loop while (and (< end (length input))
                     (char/= (char input end) #\'))
          do (when (and (char= (char input end) #\\)
                        (< (1+ end) (length input)))
               (incf end))
             (incf end))
    (values (make-token :type :string
                        :value (subseq input (1+ pos) end)
                        :position pos)
            (1+ end))))

(defun read-operator (input pos)
  "Read an operator from input starting at pos."
  (let* ((char (char input pos))
         (next (if (< (1+ pos) (length input))
                   (char input (1+ pos))
                   nil)))
    (cond
      ((and (char= char #\<) (eql next #\=))
       (values (make-token :type :lte :value "<=" :position pos) (+ pos 2)))
      ((and (char= char #\>) (eql next #\=))
       (values (make-token :type :gte :value ">=" :position pos) (+ pos 2)))
      ((and (char= char #\!) (eql next #\=))
       (values (make-token :type :neq :value "!=" :position pos) (+ pos 2)))
      ((and (char= char #\<) (eql next #\>))
       (values (make-token :type :neq :value "<>" :position pos) (+ pos 2)))
      (t (values (make-token :type (case char
                                     (#\= :eq)
                                     (#\< :lt)
                                     (#\> :gt)
                                     (#\+ :plus)
                                     (#\- :minus)
                                     (#\* :star)
                                     (#\/ :slash))
                             :value (string char)
                             :position pos)
                 (1+ pos))))))
