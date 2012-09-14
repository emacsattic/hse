Description
===========

Help editing HTML files in which there are multiple types of source
code, such as the embedded javascript code.

This package is inspired by the "org-edit-src-code" from Org-mode.

Installation
============

In your emacs config:

    (add-to-list 'load-path "/path/to/hse.el")
    (require 'hse)

And optionally bind "hse-edit-enclosing-code-block" to key "C-c '" (or
any other keys you prefer):

    (require 'sgml-mode)
    (add-hook 'html-mode-hook
	  (lambda ()
	    (local-set-key "\C-c'" 'hse-edit-enclosing-code-block)))
	  
While editing files, invoke "hse-edit-enclosing-code-block" when your
cursor is placed inside code blocks. Similar to Org-mode, it will open
a new buffer for editing, in the desired major mode. The boundary of
code blocks and the corresponding major modes used are specified in
"hse-mode-block-alist".

After editing is done, use "C-c '" (C-c and single quote, like what
you use in Org-mode) again to ship the changes back to the original
file.
