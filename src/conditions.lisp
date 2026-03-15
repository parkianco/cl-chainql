;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-chainql)

(define-condition cl-chainql-error (error)
  ((message :initarg :message :reader cl-chainql-error-message))
  (:report (lambda (condition stream)
             (format stream "cl-chainql error: ~A" (cl-chainql-error-message condition)))))
