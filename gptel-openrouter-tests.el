;;; gptel-openrouter-tests.el --- Tests for the gptel-openrouter package  -*- lexical-binding: t; -*-

(defconst test-cache-location (file-name-directory (buffer-file-name))
  "Holds the location of the current test file.")

(defconst test-models-data-file-name "models-test-data.json"
  "Name of the test data file containing model information.")


(defmacro with-fixture (&rest body)
  "Set up bindings for oi-related tests and execute BODY."
  `(let ((oi--json-cache-content nil)
         (oi-json-cache-location test-cache-location)
         (oi--json-cache-file test-models-data-file-name))
     ,@body))


(defmacro with-model-data-fixture (&rest body)
  "Set up bindings for tests getting properties from model-data and execute BODY.

The code in BODY can access a `model-data' variable, whose value is the
data of the model with id \"model1-id\" obtained from the test data json
file."
  `(let* ((oi--json-cache-content nil)
          (oi-json-cache-location test-cache-location)
          (oi--json-cache-file test-models-data-file-name)
          (id "model1-id")
          (model-data (oi--get-model-data id)))
     ,@body))


(ert-deftest test-oi--get-json-cache-fullpah ()
  (let ((oi-json-cache-location "/tmp/")
        (oi--json-cache-file "test.json"))
    (should (string= (oi--get-json-cache-fullpah) "/tmp/test.json")))

  (let ((expected-path
         (file-name-concat oi-json-cache-location oi--json-cache-file)))
    (should (string= (oi--get-json-cache-fullpah) expected-path))))


(ert-deftest test-oi--get-json-content ()
  ;; (let ((oi--json-cache-content "The Cache"))
  ;;   ;; Whatever is in the cache
  ;;   (should (string= (oi--get-json-content) "The Cache")))
  ;; (test-fixture-setup
  ;; (lambda ()
  ;;   ))
  (with-fixture
   (let* (return)
     ;; Just to make sure the test file exists
     (should (file-exists-p (oi--get-json-cache-fullpah)))

     (let ((content (oi--get-json-content)))
       (should (not (null content)))
       (should (listp content))
       ;; Check there is a data field
       (should (assoc 'data content))
       ;; Check the cache is set and equal to the content
       (should (equal oi--json-cache-content content))))))


(ert-deftest test-oi--get-model-data ()
  (with-fixture
   (let* ((id "model1-id")
          (data (oi--get-model-data id))
          (expected-description "The first model."))
     (should (equal (alist-get 'description data) expected-description)))))


(ert-deftest test-oi--get-model-description ()
  (with-model-data-fixture
   (let ((obtained (oi--get-model-description model-data))
         (expected "The first model."))
     (should (equal obtained expected)))))


(ert-deftest test-oi--get-model-capabilities ()
  ;; TODO: Implement-me 
  )


(ert-deftest test-oi--get-model-mime-types ()
  ;; TODO: Implement-me 
  )


(ert-deftest test-oi--get-model-context-window ()
  (with-model-data-fixture
   (let ((obtained (oi--get-model-context-window model-data))
         (expected 50))
     (should (eq obtained expected)))))


(ert-deftest test-oi--get-model-input-cost ()
  (with-model-data-fixture
   (let ((obtained (oi--get-model-input-cost model-data))
         (expected 2.5))
     (should (equal obtained expected)))))


(ert-deftest test-oi--get-model-output-cost ()
  (with-model-data-fixture
   (let ((obtained (oi--get-model-output-cost model-data))
         (expected 10.0))
     (should (equal obtained expected)))))


(ert-deftest test-oi--get-model-cutoff-date ()
  (with-model-data-fixture
   (let* ((obtained (oi--get-model-cutoff-date model-data))
          (unix-epoc 1715558400)
          (expected
           (format-time-string "%Y-%m-%d" (seconds-to-time unix-epoc))))
     (should (equal obtained expected)))))


(ert-deftest test-oi--get-model-plist-for-gptel ()
  (with-fixture
   (let* ((model-data-1 (oi--get-model-plist-for-gptel 'model1-id))
          (model-data-2 (oi--get-model-plist-for-gptel 'invalid-id)))

     (should (not (eq model-data-1 'model1-id)))
     (should (plistp (cdr model-data-1)))

     (should (eq model-data-2 'invalid-id)))))


(ert-deftest test-oi-get-annotated-models ()
  (with-fixture
   (let* ((models '(model1-id invalid-model))
          (annotated-models (oi-get-annotated-models models)))

     (pcase-let* ((`(,annotated-model1 ,annotated-model2) annotated-models))
       ;; Second model is returned as is, since there is no data for it in the JSON file
       (should (eq annotated-model2 'invalid-model))

       (should
        (equal
         (cdr annotated-model1)
         (cdr (oi--get-model-plist-for-gptel 'model1-id))))))))


;; Local Variables:
;; read-symbol-shorthands: (("oi-" . "gptel-openrouter-"))
;; End:
