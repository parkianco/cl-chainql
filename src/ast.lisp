;;;; Copyright (c) 2024-2026 Parkian Company LLC. All rights reserved.
;;;; SPDX-License-Identifier: Apache-2.0

;;;; cl-chainql - AST Structures
;;;;
;;;; Abstract Syntax Tree definitions for ChainQL queries.

(in-package #:cl-chainql)

;;; Query AST - top level container
(defstruct query-ast
  (type nil :type keyword)
  (components nil :type list))

;;; Clause structures
(defstruct select-clause
  (columns nil :type list)
  (distinct nil))

(defstruct from-clause
  (tables nil :type list))

(defstruct where-clause
  (condition nil))

(defstruct order-clause
  (columns nil :type list))

(defstruct limit-clause
  (count nil)
  (offset nil))

(defstruct join-clause
  (type nil)
  (table nil)
  (condition nil))

(defstruct group-clause
  (columns nil :type list))

(defstruct having-clause
  (condition nil))

;;; Reference structures
(defstruct column-ref
  (table nil)
  (name nil)
  (alias nil))

(defstruct table-ref
  (name nil)
  (alias nil))

;;; Expression structures
(defstruct expr-binary
  (op nil)
  (left nil)
  (right nil))

(defstruct expr-unary
  (op nil)
  (arg nil))

(defstruct expr-func
  (name nil)
  (args nil :type list))

(defstruct expr-literal
  (value nil)
  (type nil))

(defstruct expr-subquery
  (query nil))
