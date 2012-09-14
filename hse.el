;;; hse.el --- Help editing HTML files with different types of sources.

;; Copyright (C) 2012 Chen Zhuhui

;; Author: Chen Zhuhui <ekschencn@gmail.com>
;; Keywords: edit
;; Version: 0.1

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; When editing HTML files, it is common dealing with various types of
;; source code, such as javascript code, css code, etc., in one file.
;; Inspired by the source editing way that Org-mode offers for the
;; BEGIN_SRC tag, I wrote this simple package for doing my edit job
;; for the HTML files.

;; Setting the `hse-mode-block-alist' and place the point inside a
;; code block, invoke `hse-edit-enclosing-code-block', then a new
;; buffer will be created for editing that block of code, with the
;; desired major mode's on. When done editing, use "\C-c'" to ship the
;; changes back, just like what you'll do when using Org-mode.

;;; Code:

(eval-when-compile (require 'cl))

(defcustom hse-mode-block-alist
  '((("<script>" . "</script>") . js2-mode)
    (("<style>" . "</style>") . css-mode))
  "Alist of block delimiters patterns vs corresponding major mode functions.

Each element looks like ((BEGIN-DELIMITER . END-DELIMITER) . MODE).
BEGIN-DELIMITER and END-DELIMITER specify the beginning and ending of a code block.
MODE is the major mode used for editing the code block.")

(defun hse-edit-enclosing-code-block ()
  "Edit the enclosing code block around point.

It will first try to find out what the enclosing code block is,
by trying matching each element in `hse-mode-block-alist' in
order until it finds one. Then it will open a new buffer with the
corresponding major mode for doing the editing.

When edits are done, use `hse-update-and-kill' (or its key
binding \"\\C-c'\") to ship the changes to the buffer originating
this command and kill the edit buffer."
  (interactive)
  (let ((code-block-info (hse-find-mode-match)))
    (when code-block-info
      (let ((base-buffer (current-buffer))
	    (target-major-mode (car code-block-info))
	    (code-beg (cadr code-block-info))
	    (code-end  (cddr code-block-info))
	    (edit-buffer (get-buffer
			  (format "*Hybrid Source Edit - %s*"
				  (buffer-name (current-buffer))))))
	(block nil
	  (if edit-buffer
	      (if (yes-or-no-p "Changes to another code block will be discarded. Proceed?")
		  (kill-buffer edit-buffer)
		(return)))
	  (setq edit-buffer (get-buffer-create (format "*Hybrid Source Edit - %s*"
						       (buffer-name base-buffer))))
	  (copy-to-buffer edit-buffer code-beg code-end)
	  (with-current-buffer edit-buffer
	    (funcall target-major-mode)
	    (set (make-local-variable 'hse-base-buffer) base-buffer)
	    (set (make-local-variable 'hse-code-beg) code-beg)
	    (set (make-local-variable 'hse-code-end) code-end)
	    (local-set-key "\C-c'" 'hse-update-and-kill)
	    (pop-to-buffer edit-buffer)))))))

(defun hse-update-and-kill ()
  "Ship the changes to the originating buffer and kill the edit buffer."
  (interactive)
  (let ((new-code (buffer-substring-no-properties (point-min) (point-max)))
	(old-code-beg hse-code-beg)
	(old-code-end hse-code-end))
    (with-current-buffer hse-base-buffer
      (delete-region old-code-beg old-code-end)
      (save-excursion
	(goto-char old-code-beg)
	(insert new-code)))
    (quit-window t)))

(defun hse-find-block-by-delims-bf (beg-delim end-delim)
  (let ((cursor (point))
	code-beg code-end
	beg)
    (save-excursion
      (setq code-beg (search-backward-regexp beg-delim nil t))
      (when code-beg
	(goto-char (+ (point) (length (match-string 0))))
	(setq beg (point))
	(setq code-end (search-forward-regexp end-delim nil t))
	(when (and code-beg code-end
		   (<= code-beg cursor) (< cursor code-end))
	  (cons beg (- code-end (length (match-string 0)))))))))

(defun hse-find-block-by-delims-fb (beg-delim end-delim)
  (let ((cursor (point))
	code-beg code-end
	end)
    (save-excursion
      (setq code-end (search-forward-regexp end-delim nil t))
      (when code-end
	(goto-char (- (point) (length (match-string 0))))
	(setq end (point))
	(setq code-beg (search-backward-regexp beg-delim nil t))
	(when (and code-beg code-end
		   (<= code-beg cursor) (< cursor code-end))
	  (cons (+ code-beg (length (match-string 0))) end))))))

(defun hse-find-block-by-delims (beg-delim end-delim)
  (let ((boundary (hse-find-block-by-delims-bf beg-delim end-delim)))
    (unless boundary
      (setq boundary (hse-find-block-by-delims-fb beg-delim end-delim)))
    boundary))

(defun hse-find-mode-match ()
  (let ((case-fold-search t))
    (let ((match (dolist (entry hse-mode-block-alist)
		   (let* ((delims (car entry))
			  (boundary (hse-find-block-by-delims (car delims) (cdr delims))))
		     (when boundary
		       (return (cons (cdr entry) boundary)))))))
      (or match (error "No matching code block is found around point.")))))

(provide 'hse)

;;; hse.el ends here
