# cl-chainql

Pure Common Lisp implementation of Chainql

## Overview
This library provides a robust, zero-dependency implementation of Chainql for the Common Lisp ecosystem. It is designed to be highly portable, performant, and easy to integrate into any SBCL/CCL/ECL environment.

## Getting Started

Load the system using ASDF:

```lisp
(asdf:load-system #:cl-chainql)
```

## Usage Example

```lisp
;; Initialize the environment
(let ((ctx (cl-chainql:initialize-chainql :initial-id 42)))
  ;; Perform batch processing using the built-in standard toolkit
  (multiple-value-bind (results errors)
      (cl-chainql:chainql-batch-process '(1 2 3) #'identity)
    (format t "Processed ~A items with ~A errors.~%" (length results) (length errors))))
```

## License
Apache-2.0
