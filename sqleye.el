;;; sqleye.el --- SQL Interactive Client Wrapper -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Nan0Scho1ar
;;
;; Author: Nan0Scho1ar <https://github.com/nan0scho1ar>
;; Maintainer: Nan0Scho1ar <scorch267@gmail.com>
;; Created: May 17, 2022
;; Modified: May 17, 2022
;; Version: 0.9
;; Keywords: abbrev bib c calendar comm convenience data docs emulations extensions faces files frames games hardware help hypermedia i18n internal languages lisp local maint mail matching mouse multimedia news outlines processes terminals tex tools unix vc wp
;; Homepage: https://github.com/nan0scho1ar/sqleye
;; Package-Requires: ((emacs "27.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Simple wrapper for interactive SQL mode to make it more
;; friendly with things like org code blocks.
;;
;;; Code:

(require 'sql)

(defvar sqleye-buffer "* SQLeye *"
  "The name of the SQLeye buffer.")

(defun sqleye-send-string (str)
  "Send the string STR to the SQL process."
  (interactive "sSQL Text: ")
  (let ((comint-input-sender-no-newline nil)
        (s (replace-regexp-in-string "[[:space:]\n\r]+\\'" "" str)))
    (if (get-buffer sqleye-buffer)
        (progn
          (save-excursion
            (with-current-buffer sqleye-buffer
              (when sql-debug-send
                (message ">>SQL> %S" s))
              ;; Send the string (trim the trailing whitespace)
              (sql-input-sender (get-buffer-process (current-buffer)) s)
              ;; Send a command terminator if we must
              (sql-send-magic-terminator sqleye-buffer s sql-send-terminator))))
      ;; We don't have no stinkin' sql
      (user-error (format "No such buffer %s" sqleye-buffer)))))

(defun sqleye-send-region (start end)
  "Send text from START to END to the SQL process using SQLeye."
  (interactive "r")
  (sqleye-send-string (buffer-substring-no-properties start end)))

(defun sqleye-buffer-send-region (start end)
  "Send text from START to END to the SQL process using SQLeye.

this is basically sqleye-send-region but for the interactive buffer.
Required because evaluating leaves the text selected for some reason."
  (interactive "r")
  (sqleye-send-string (buffer-substring-no-properties start end))
  (transient-mark-mode -1))

(defun sqleye-pop-buffer ()
  "Pop open the sqleye buffer."
  (let ((direction `((direction . below)
                     (window-height . ,(/ (window-height) 2)))))
    (pop-to-buffer
     sqleye-buffer
     `(display-buffer-in-direction . ,direction)
     t))
  (select-window (previous-window)))

(defun sqleye-live-p ()
  "Return non-nil if the process associated with sqleye is live."
  (sql-buffer-live-p sqleye-buffer))

(defun sqleye-connect ()
  "Prompt user to start a new SQL Connection."
  (interactive)
  (when (get-buffer sqleye-buffer)
    (if (sqleye-live-p)
        (kill-buffer-ask sqleye-buffer)
      (kill-buffer sqleye-buffer)))
  (call-interactively #'sql-connect)
  (rename-buffer sqleye-buffer)
  (delete-window)
  (sqleye-pop-buffer))

(defun sqleye-toggle-buffer ()
  "Toggle SQLeye buffer if exists, else start a new connection."
  (interactive)
  (if (sqleye-live-p)
      (if (get-buffer-window sqleye-buffer)
          (delete-window (get-buffer-window sqleye-buffer))
        (sqleye-pop-buffer))
    (sqleye-connect)))

(provide 'sqleye)
;;; sqleye.el ends here
