;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;; SPDX-License-Identifier: Apache-2.0

(in-package #:cl-chainql)

;;; Core types for cl-chainql
(deftype cl-chainql-id () '(unsigned-byte 64))
(deftype cl-chainql-status () '(member :ready :active :error :shutdown))
