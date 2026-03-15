;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(defpackage #:cl-chainql.test
  (:use #:cl #:cl-chainql)
  (:export #:run-tests))

(in-package #:cl-chainql.test)

(defun run-tests ()
  (format t "Executing functional test suite for cl-chainql...~%")
  (assert (equal (matrix-multiply '((1 2) (3 4)) '((5 6) (7 8))) '((19 22) (43 50))))
  (assert (< (abs (- (reduce #'+ (soft-max '(1.0 2.0 3.0))) 1.0)) 1e-5))
  (format t "All functional tests passed!~%")
  t)
