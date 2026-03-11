;;;; cl-chainql test package

(defpackage #:cl-chainql.test
  (:use #:cl #:cl-chainql)
  (:export #:run-tests))

(in-package #:cl-chainql.test)

(defvar *test-results* nil)
(defvar *test-count* 0)
(defvar *pass-count* 0)
(defvar *fail-count* 0)

(defmacro deftest (name &body body)
  "Define a test case."
  `(progn
     (defun ,name ()
       (handler-case
           (progn ,@body t)
         (error (e)
           (push (cons ',name e) *test-results*)
           nil)))
     (pushnew ',name *all-tests*)))

(defvar *all-tests* nil)

(defmacro assert-equal (expected actual &optional message)
  "Assert that expected equals actual."
  `(let ((exp ,expected)
         (act ,actual))
     (unless (equal exp act)
       (error "~@[~A: ~]Expected ~S but got ~S" ,message exp act))))

(defmacro assert-true (expr &optional message)
  "Assert that expression is true."
  `(unless ,expr
     (error "~@[~A: ~]Expected true but got false" ,message)))

(defmacro assert-nil (expr &optional message)
  "Assert that expression is nil."
  `(when ,expr
     (error "~@[~A: ~]Expected nil but got ~S" ,message ,expr)))

(defun run-tests ()
  "Run all tests and report results."
  (setf *test-results* nil
        *test-count* 0
        *pass-count* 0
        *fail-count* 0)
  (dolist (test (reverse *all-tests*))
    (incf *test-count*)
    (format t "Running ~A... " test)
    (if (funcall test)
        (progn
          (incf *pass-count*)
          (format t "PASS~%"))
        (progn
          (incf *fail-count*)
          (format t "FAIL~%"))))
  (format t "~%Results: ~D/~D passed, ~D failed~%"
          *pass-count* *test-count* *fail-count*)
  (zerop *fail-count*))
