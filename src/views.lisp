;;;; cl-chainql - Materialized Views
;;;;
;;;; Support for defining and managing materialized views.

(in-package #:cl-chainql)

(defstruct view-definition
  (name nil)
  (query nil)
  (materialized nil :type boolean)
  (refresh-interval nil)
  (last-refresh nil)
  (cached-data nil))

(defvar *views* (make-hash-table :test #'equal)
  "Global registry of view definitions.")

(defun create-view (name query &key materialized refresh-interval)
  "Create a new view definition.
NAME is a string identifier for the view.
QUERY is the ChainQL query string defining the view.
MATERIALIZED if true, the view caches results.
REFRESH-INTERVAL is seconds between automatic refreshes (for materialized views)."
  (setf (gethash name *views*)
        (make-view-definition :name name
                              :query query
                              :materialized materialized
                              :refresh-interval refresh-interval)))

(defun drop-view (name)
  "Remove a view definition."
  (remhash name *views*))

(defun get-view (name)
  "Get a view definition by name."
  (gethash name *views*))

(defun refresh-materialized-view (name data-sources)
  "Refresh a materialized view's cached data.
Returns the refreshed query result."
  (let ((view (get-view name)))
    (when (and view (view-definition-materialized view))
      (let* ((ast (parse-query (view-definition-query view)))
             (plan (optimize-query ast))
             (result (execute-query plan data-sources)))
        (setf (view-definition-cached-data view) result)
        (setf (view-definition-last-refresh view) (get-universal-time))
        result))))

(defun materialized-view (name)
  "Check if a view is materialized."
  (let ((view (get-view name)))
    (when view
      (view-definition-materialized view))))

(defun query-view (name data-sources &key force-refresh)
  "Query a view, using cached data for materialized views.
FORCE-REFRESH if true, refreshes the cache even if not stale."
  (let ((view (get-view name)))
    (unless view
      (error 'query-error :message (format nil "View not found: ~A" name)))
    (cond
      ((and (view-definition-materialized view)
            (not force-refresh)
            (view-definition-cached-data view)
            (not (view-stale-p view)))
       (view-definition-cached-data view))
      ((view-definition-materialized view)
       (refresh-materialized-view name data-sources))
      (t
       (let* ((ast (parse-query (view-definition-query view)))
              (plan (optimize-query ast)))
         (execute-query plan data-sources))))))

(defun view-stale-p (view)
  "Check if a materialized view needs refresh."
  (let ((interval (view-definition-refresh-interval view))
        (last-refresh (view-definition-last-refresh view)))
    (or (null last-refresh)
        (and interval
             (> (- (get-universal-time) last-refresh) interval)))))

(defun list-views ()
  "Return a list of all defined view names."
  (let ((names nil))
    (maphash (lambda (k v)
               (declare (ignore v))
               (push k names))
             *views*)
    (nreverse names)))

(defun clear-views ()
  "Remove all view definitions."
  (clrhash *views*))
