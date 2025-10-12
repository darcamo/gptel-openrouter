;;; gptel-openrouter.el --- Get information about openrouter models  -*- lexical-binding: t; -*-

;; Copyright (C) 2025  Darlan Cavalcante Moreira

;; Author: Darlan Cavalcante Moreira <darcamo@gmail.com>
;; Keywords:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Obtain information about the models available at openrouter.ai through a JSON
;; file they provide. The primary purpose of this package is to create plists
;; for your desired models, ensuring compatibility with =gptel-make-openai=.
;; This allows you to receive detailed annotations for the models, including
;; descriptions, context lengths, prices, and more.

;;; Code:

(require 'url)


(defvar oi--json-cache-file "models.json"
  "Name of the local JSON file with model information.")


(defvar oi--already-warned nil
  "Whether we have already warned the user about the missing JSON file.")


(defvar oi--json-cache-content nil
  "Cache for the json content.")


(defcustom oi-json-uri "https://openrouter.ai/api/v1/models"
  "URI of the JSON file with model information."
  :type '(string)
  :group 'gptel-openrouter)


(defcustom oi-json-cache-location
  (file-name-concat user-emacs-directory ".cache/gptel-openrouter")
  "Location of the JSON file with model information."
  :type '(string)
  :group 'gptel-openrouter)


(defun oi--get-json-cache-fullpah ()
  "Get the full path of the JSON cache file."
  (if (and oi--json-cache-file oi-json-cache-location)
      (file-name-concat oi-json-cache-location oi--json-cache-file)
    (error "Both gptel-openrouter--json-cache-file and gptel-openrouter-json-cache-location must be set")))


(defun oi-download-model-data ()
  "Download the JSON file and store it in the users Emacs directory."
  (interactive)
  (let* ((cache-dir oi-json-cache-location)
         (cache-file (oi--get-json-cache-fullpah))
         (file-exists (file-exists-p cache-file))
         (file-age
          (if file-exists
              (float-time
               (time-subtract
                (current-time)
                (file-attribute-modification-time
                 (file-attributes cache-file))))
            nil))
         (one-day (* 24 60 60)))

    ;; Create the cache directory if it doesn't exist
    (unless (file-directory-p cache-dir)
      (make-directory cache-dir t))

    ;; Download the file if it doesn't exist or is older than one day
    (when (or (not file-exists) (and file-age (> file-age one-day)))
      (url-copy-file oi-json-uri cache-file t))))


(defun oi--get-json-content ()
  "Get the JSON content with the models' information.

This function caches the content in memory to avoid multiple reads. If
the cache is empty, it downloads the file if necessary and reads it from
disk. Then it parses the JSON, stores it in the cache, and returns it."
  (if oi--json-cache-content
      oi--json-cache-content

    ;; Read the file from the downloaded location
    (let ((file-path (oi--get-json-cache-fullpah)))
      (if (not (file-exists-p file-path))
          ;; We don't have the JSON file with the model data
          nil
        ;; Read the JSON content
        (setq oi--json-cache-content (json-read-file file-path))
        oi--json-cache-content))))


(defun oi--get-model-data (model-id)
  "Get data for the model with ID MODEL-ID.

Returns an alist with the model information, or nil if the model is not
in the data."
  (interactive)
  (if-let* ((content (oi--get-json-content))
            (data (alist-get 'data content))
            (predicate
             `(lambda (entry) (equal (alist-get 'id entry) ,model-id))))

    ;; map-nested-elt
    (nth 0 (seq-filter predicate data))))


(defun oi--plist-remove-nil (plist)
  "Remove nil values from PLIST."
  (let ((result nil))
    (while plist
      (let ((key (pop plist))
            (val (pop plist)))
        (unless (null val)
          (setq result (append result (list key val))))))
    result))


(defun oi--get-model-description (model-data)
  "Get the description of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  (alist-get 'description model-data))


(defun oi--get-model-capabilities (_model-data)
  "Get the capabilities of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  ;; TODO: Implement-me
  ;; Ex: :capabilities (media tool json url)
  nil)


;; mime-types
(defun oi--get-model-mime-types (_model-data)
  "Get the mime-types of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  ;; TODO: Implement-me
  nil)


;; Returning the value in thousands because that seems to be what gptel expects
(defun oi--get-model-context-window (model-data)
  "Get the context-window (in thousands) of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  (let ((context-window (alist-get 'context_length model-data)))
    (/ context-window 1000)))


(defun oi--get-model-input-cost (model-data)
  "Get the input-cost per million tokens of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  (let ((cost
         (string-to-number
          (alist-get 'prompt (alist-get 'pricing model-data)))))
    (* cost 1000000)))


(defun oi--get-model-output-cost (model-data)
  "Get the output-cost per million tokens of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  (let ((cost
         (string-to-number
          (alist-get 'completion (alist-get 'pricing model-data)))))
    (* cost 1000000)))


(defun oi--get-model-cutoff-date (model-data)
  "Get the cutoff-date of the model from MODEL-DATA.

MODEL-DATA is the alist returned by `oi--get-model-data'."
  (let ((unix-epoch (alist-get 'created model-data)))
    (format-time-string "%Y-%m-%d" (seconds-to-time unix-epoch))))


;;   "List of available OpenAI models and associated properties we can pass to gptel.
;; Keys:
;; - `:description': a brief description of the model.
;; - `:capabilities': a list of capabilities supported by the model.
;; - `:mime-types': a list of supported MIME types for media files.
;; - `:context-window': the context window size, in thousands of tokens.
;; - `:input-cost': the input cost, in US dollars per million tokens.
;; - `:output-cost': the output cost, in US dollars per million tokens.
;; - `:cutoff-date': the knowledge cutoff date.
;; - `:request-params': a plist of additional request parameters to
;;   include when using this model.


(defun oi--warn-if-json-file-is-missing ()
  "Warn the user if the json file with model data is missing."
  (unless (or gptel-openrouter--already-warned
              (file-exists-p (gptel-openrouter--get-json-cache-fullpah)))
    (display-warning
     :gptel-openrouter
     "JSON file with model data is missing. Please run
`gptel-openrouter-download-model-data` to download it.")
    (setq gptel-openrouter--already-warned t)))


(defun oi--get-model-plist-for-gptel (model-symbol)
  "Get the model data for MODEL-SYMBOL.

The returned data is one of the elements of the `:models` list passed to
`gptel-make-openai`.

If the model is not found in the openrouter data, return MODEL-SYMBOL as
is."
  (oi--warn-if-json-file-is-missing)

  (if-let* ((model-name (symbol-name model-symbol))
            (model-data (oi--get-model-data model-name)))
    (let* ((description (oi--get-model-description model-data))
           (capabilities (oi--get-model-capabilities model-data))
           (mime-types (oi--get-model-mime-types model-data))
           (context-window (oi--get-model-context-window model-data))
           (input-cost (oi--get-model-input-cost model-data))
           (output-cost (oi--get-model-output-cost model-data))
           (cutoff-date (oi--get-model-cutoff-date model-data))
           ;; (request-params (alist-get 'request_params model-data))
           (model-properties
            (list
             :description description
             :capabilities capabilities
             :mime-types mime-types
             :context-window context-window
             :input-cost input-cost
             :output-cost output-cost
             :cutoff-date cutoff-date
             ;; :request-params request-params
             )))
      (cons model-symbol (oi--plist-remove-nil model-properties)))
    model-symbol))


;;;###autoload (autoload 'gptel-openrouter-get-annotated-models "gptel-openrouter")
(defun oi-get-annotated-models (models)
  "Return a list of annotated MODELS for use with gptel.

MODELS should be a list of symbols representing the model names you wish
to include in gptel. This list is typically passed as the `:models'
property to `gptel-make-openai'. What
`gptel-openrouter-get-annotated-models' does is returning a list
containing the same models enriched with additional information, such as
context window size, cost, and more, which gptel will display."
  (mapcar #'oi--get-model-plist-for-gptel models))


;; Some "nice to have" for the future:
;;
;; TODO: Create a function that shows all models in the cache file in a tabulated
;; list
;;
;; TODO: Allow filtering the tabulated list by capabilities, context window size,
;; etc


(provide 'gptel-openrouter)
;;; gptel-openrouter.el ends here

;; Local Variables:
;; read-symbol-shorthands: (("oi-" . "gptel-openrouter-"))
;; End:
