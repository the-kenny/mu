;;; mm.el -- part of mm, the mu mail user agent
;;
;; Copyright (C) 2011 Dirk-Jan C. Binnema

;; Author: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Maintainer: Dirk-Jan C. Binnema <djcb@djcbsoftware.nl>
;; Keywords: email
;; Version: 0.0

;; This file is not part of GNU Emacs.
;;
;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(eval-when-compile (require 'cl))

(require 'mm-hdrs)
(require 'mm-view)
(require 'mm-send)
(require 'mm-proc)


;; TODO: get this version through to Makefile magic
(defconst mm/version "0.9.8pre"
  "*internal* my version")

;; Customization

(defgroup mm nil
  "Mm." :group 'local)


(defcustom mm/mu-home nil
  "Location of the mu homedir, or nil for the default."
  :type 'directory
  :group 'mm
  :safe 'stringp)

(defcustom mm/mu-binary "mu"
  "Name of the mu-binary to use; if it cannot be found in your
PATH, you can specifiy the full path."
  :type 'file
  :group 'mm
  :safe 'stringp)

(defcustom mm/maildir nil
  "Your Maildir directory. When `nil', mu will try to find it."
  :type 'directory
  :safe 'stringp
  :group 'mm)


(defcustom mm/get-mail-command nil
  "Shell command to run to retrieve new mail; e.g. 'offlineimap' or
'fetchmail'."
  :type 'string
  :group 'mm
  :safe 'stringp)

(defcustom mm/attachment-dir (expand-file-name "~/")
  "Default directory for saving attachments."
  :type 'string
  :group 'mm
  :safe 'stringp)


(defvar mm/debug nil
  "When set to non-nil, log debug information to the *mm-log* buffer.")

;; Folders

(defgroup mm/folders nil
  "Special folders for mm."
  :group 'mm)


(defcustom mm/inbox-folder nil
  "Your Inbox folder, relative to `mm/maildir', e.g. \"/Inbox\"."
  :type 'string
  :safe 'stringp
  :group 'mm/folders)

(defcustom mm/sent-folder nil
  "Your folder for sent messages, relative to `mm/maildir',
  e.g. \"/Sent Items\"."
  :type 'string
  :safe 'stringp
  :group 'mm/folders)

(defcustom mm/draft-folder nil
  "Your folder for draft messages, relative to `mm/maildir',
  e.g. \"/drafts\""
  :type 'string
  :safe 'stringp
  :group 'mm/folders)

(defcustom mm/trash-folder nil
  "Your folder for trashed messages, relative to `mm/maildir',
  e.g. \"/trash\"."
  :type 'string
  :safe 'stringp
  :group 'mm/folders)


(defcustom mm/move-quick-targets nil
  "A list of targets quickly moving messages towards (i.e.,
  archiving or refiling). The list contains elements of the form
 (foldername . shortcut), where FOLDERNAME is a maildir (such as
\"/archive/\"), and shortcut a single shortcut character. With
this, in the header buffer and view buffer you can execute
`mm/mark-for-move-quick' (or 'a', by default) followed by the designated
character for the target folder, and the message at point (or all
the messages in the region) will be marked for moving to the target
folder.")


;; the headers view
(defgroup mm/headers nil
  "Settings for the headers view."
  :group 'mm)


(defcustom mm/header-fields
    '( (:date          .  25)
       (:flags         .   6)
       (:from          .  22)
       (:subject       .  40))
  "A list of header fields to show in the headers buffer, and their
  respective widths in characters. A width of `nil' means
  'unrestricted', and this is best reserved fo the rightmost (last)
  field. For the complete list of available headers, see `mm/header-names'")

;; the message view
(defgroup mm/view nil
  "Settings for the message view."
  :group 'mm)

(defcustom mm/view-fields
  '(:from :to :cc :subject :flags :date :maildir :path :attachments)
  "Header fields to display in the message view buffer. For the
complete list of available headers, see `mm/header-names'"
  :type (list 'symbol)
  :group 'mm/view)


;; Composing / Sending messages
(defgroup mm/compose nil
  "Customizations for composing/sending messages."
  :group 'mm)

(defcustom mm/msg-citation-prefix "> "
  "String to prefix cited message parts with."
  :type 'string
  :group 'mm/compose)

(defcustom mm/msg-reply-prefix "Re: "
  "String to prefix the subject of replied messages with."
  :type 'string
  :group 'mm/compose)

(defcustom mm/msg-forward-prefix "Fwd: "
  "String to prefix the subject of forwarded messages with."
  :type 'string
  :group 'mm/compose)

(defcustom mm/user-agent nil
  "The user-agent string; leave at `nil' for the default."
  :type 'string
  :group 'mm/compose)



;; Faces

(defgroup mm/faces nil
  "Faces used in by mm."
  :group 'mm
  :group 'faces)

(defface mm/unread-face
  '((t :inherit font-lock-keyword-face :bold t))
  "Face for an unread mm message header."
  :group 'mm/faces)

(defface mm/moved-face
  '((t :inherit font-lock-comment-face :slant italic))
  "Face for an mm message header that has been moved to some
folder (it's still visible in the search results, since we cannot
be sure it no longer matches)."
  :group 'mm/faces)

(defface mm/trashed-face
  '((t :inherit font-lock-comment-face :strike-through t))
  "Face for an message header in the trash folder."
  :group 'mm/faces)

(defface mm/draft-face
  '((t :inherit font-lock-string-face))
  "Face for a draft message header (i.e., a message with the draft
flag set)."
  :group 'mm/faces)

(defface mm/header-face
  '((t :inherit default))
  "Face for an mm header without any special flags."
  :group 'mm/faces)

(defface mm/title-face
  '((t :inherit font-lock-type-face))
  "Face for an mm title."
  :group 'mm/faces)

(defface mm/view-header-key-face
  '((t :inherit font-lock-builtin-face))
  "Face for the header title (such as \"Subject\" in the message view)."
  :group 'mm/faces)

(defface mm/view-header-value-face
  '((t :inherit font-lock-doc-face))
  "Face for the header value (such as \"Re: Hello!\" in the message view)."
  :group 'mm/faces)

(defface mm/view-link-face
  '((t :inherit font-lock-type-face :underline t))
  "Face for showing URLs and attachments in the message view."
  :group 'mm/faces)

(defface mm/view-url-number-face
  '((t :inherit font-lock-reference-face :bold t))
  "Face for the number tags for URLs."
  :group 'mm/faces)

(defface mm/view-attach-number-face
  '((t :inherit font-lock-variable-name-face :bold t))
  "Face for the number tags for attachments."
  :group 'mm/faces)

(defface mm/view-footer-face
  '((t :inherit font-lock-comment-face))
  "Face for message footers (signatures)."
  :group 'mm/faces)

(defface mm/hdrs-marks-face
  '((t :inherit font-lock-preprocessor-face))
  "Face for the mark in the headers list."
  :group 'mm/faces)

(defface mm/system-face
  '((t :inherit font-lock-comment-face :slant italic))
  "Face for system message (such as the footers for message
headers)."
  :group 'mm/faces)



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; internal variables / constants
(defconst mm/mm-buffer-name "*mm*"
  "*internal* Name of the mm main buffer.")

(defvar mm/mu-version nil
  "*interal* version of the mu binary")

(defconst mm/header-names
  '( (:attachments   .  "Attach")
     (:bcc           .  "Bcc")
     (:cc            .  "Cc")
     (:date          .  "Date")
     (:flags         .  "Flags")
     (:from          .  "From")
     (:from-or-to    .  "From/To")
     (:maildir       .  "Maildir")
     (:path          .  "Path")
     (:subject       .  "Subject")
     (:to            .  "To"))
"A alist of all possible header fields; this is used in the UI (the
column headers in the header list, and the fields the message
view). Most fields should be self-explanatory. A special one is
`:from-or-to', which is equal to `:from' unless `:from' matches ,
in which case it will be equal to `:to'.)")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; mm mode + keybindings
(defvar mm/mm-mode-map
  (let ((map (make-sparse-keymap)))

    (define-key map "I" 'mm/jump-to-inbox)
    (define-key map "T" 'mm/search-today)
    (define-key map "W" 'mm/search-last-7-days)
    (define-key map "U" 'mm/search-unread)
    (define-key map "D" 'mm/search-drafts)

    (define-key map "s" 'mm/search)
    (define-key map "q" 'mm/quit-mm)
    (define-key map "j" 'mm/jump-to-maildir)
    (define-key map "c" 'mm/compose-new)

    (define-key map "m" 'mm/toggle-mail-sending-mode)
    (define-key map "u" 'mm/retrieve-mail-update-db)

    map)
  "Keymap for the *mm* buffer.")
(fset 'mm/mm-mode-map mm/mm-mode-map)

(defun mm/mm-mode ()
  "Major mode for the mm main screen."
  (interactive)

  (kill-all-local-variables)
  (use-local-map mm/mm-mode-map)

  (setq
    mm/marks-map (make-hash-table :size 16  :rehash-size 2)
    major-mode 'mm/mm-mode
    mode-name "*mm*"
    truncate-lines t
    buffer-read-only t
    overwrite-mode 'overwrite-mode-binary))


(defun mm()
  "Start mm; should not be called directly, instead, use `mm'"
  (interactive)
  (let ((buf (get-buffer-create mm/mm-buffer-name))
	 (inhibit-read-only t))
    (with-current-buffer buf
       (erase-buffer)
       (insert
	"* "
	 (propertize "mm - mail for emacs version " 'face 'mm/title-face)
	 (propertize  mm/version 'face 'mm/view-header-value-face)
	 " (send: "
	 (propertize (if smtpmail-queue-mail "queued" "direct")
	   'face 'mm/view-header-key-face)
	 ")"
	 "\n\n"
	 "  Watcha wanna do?\n\n"
	 "    * Show me some messages:\n"
	 "      - In your " (propertize "I" 'face 'highlight) "nbox\n"
	 "      - " (propertize "U" 'face 'highlight) "nread messages\n"
	 "      - " (propertize "D" 'face 'highlight) "raft messages\n"
	 "      - Received " (propertize "T" 'face 'highlight) "oday\n"
	 "      - Received this " (propertize "W" 'face 'highlight) "eek\n"
	 "\n"
	 "    * " (propertize "j" 'face 'highlight) "ump to a folder\n"
	 "    * " (propertize "s" 'face 'highlight) "earch for a specific message\n"
	 "\n"
	 "    * " (propertize "c" 'face 'highlight) "ompose a new message\n"
	 "\n"
	 "\n"

	 "    * " (propertize "u" 'face 'highlight) "pdate email\n"
	 "    * toggle " (propertize "m" 'face 'highlight) "ail sending mode "
	 "\n"
	 "    * " (propertize "q" 'face 'highlight) "uit mm\n")
      (mm/mm-mode)
      (switch-to-buffer buf))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; interactive functions

(defun mm/jump-to-inbox ()
  "Jump to your Inbox folder (as specified in `mm/inbox-folder')."
  (interactive)
  (mm/hdrs-search (concat "maildir:" mm/inbox-folder)))

(defun mm/search-drafts ()
  "Jump to your Drafts folder (as specified in `mm/draft-folder')."
  (interactive)
  (mm/hdrs-search (concat "maildir:" mm/drafts-folder  " OR flag:draft")))

(defun mm/search-unread ()
  "List all your unread messages."
  (interactive)
  (mm/hdrs-search "flag:unread AND NOT flag:trashed"))

(defun mm/search-today ()
  "List messages received today."
  (interactive)
  (mm/hdrs-search "date:today..now"))

(defun mm/search-last-7-days ()
  "List messages received in the last 7 days."
  (interactive)
  (mm/hdrs-search "date:7d..now"))

(defun mm/retrieve-mail-update-db ()
  "Get new mail and update the database."
  (interactive)
  (mm/proc-retrieve-mail-update-db))

(defun mm/toggle-mail-sending-mode ()
  "Toggle sending mail mode, either queued or direct."
  (interactive)
  (setq smtpmail-queue-mail (not smtpmail-queue-mail))
  (mm))






;; General helper functions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mm/quit-mm()
  "Quit the mm session."
  (interactive)
  (when (y-or-n-p "Are you sure you want to quit mm? ")
    (message nil)
    (mm/kill-proc)
    (kill-buffer)))

;; TODO: make this recursive
(defun mm/get-sub-maildirs (maildir)
  "Get all readable sub-maildirs under MAILDIR."
  (let ((maildirs (remove-if
		    (lambda (dentry)
		      (let ((path (concat maildir "/" dentry)))
			(or
			  (string= dentry ".")
			  (string= dentry "..")
			  (not (file-directory-p path))
			  (not (file-readable-p path))
			  (file-exists-p (concat path "/.noindex")))))
		    (directory-files maildir))))
    (map 'list (lambda (dir) (concat "/" dir)) maildirs)))



(defun mm/ask-maildir (prompt)
  "Ask user with PROMPT for a maildir name, if fullpath is
non-nill, return the fulpath (i.e., `mm/maildir' prepended to the
chosen folder)."
  (unless (and mm/inbox-folder mm/drafts-folder mm/sent-folder)
    (error "`mm/inbox-folder', `mm/drafts-folder' and
    `mm/sent-folder' must be set"))
  (unless mm/maildir (error "`mm/maildir' must be set"))
  (interactive)
  (ido-completing-read prompt (mm/get-sub-maildirs mm/maildir)))


(defun mm/new-buffer (bufname)
  "Return a new buffer BUFNAME; if such already exists, kill the
old one first."
  (when (get-buffer bufname)
    (progn
      (message (format "Killing %s" bufname))
      (kill-buffer bufname)))
  (get-buffer-create bufname))



;;; converting flags->string and vice-versa ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun mm/flags-to-string (flags)
  "Remove duplicates and sort the output of `mm/flags-to-string-raw'."
  (concat
    (sort (remove-duplicates (append (mm/flags-to-string-raw flags) nil)) '>)))

(defun mm/flags-to-string-raw (flags)
  "Convert a list of flags into a string as seen in Maildir
message files; flags are symbols draft, flagged, new, passed,
replied, seen, trashed and the string is the concatenation of the
uppercased first letters of these flags, as per [1]. Other flags
than the ones listed here are ignored.

Also see `mm/flags-to-string'.

\[1\]: http://cr.yp.to/proto/maildir.html"
  (when flags
    (let ((kar (case (car flags)
		 ('draft     ?D)
		 ('flagged   ?F)
		 ('new       ?N)
		 ('passed    ?P)
		 ('replied   ?R)
		 ('seen      ?S)
		 ('trashed   ?T)
		 ('attach    ?a)
		 ('encrypted ?x)
		 ('signed    ?s)
		 ('unread    ?u))))
      (concat (and kar (string kar))
	(mm/flags-to-string-raw (cdr flags))))))


(defun mm/string-to-flags (str)
  "Remove duplicates from the output of `mm/string-to-flags-1'"
  (remove-duplicates (mm/string-to-flags-1 str)))

(defun mm/string-to-flags-1 (str)
  "Convert a string with message flags as seen in Maildir
messages into a list of flags in; flags are symbols draft,
flagged, new, passed, replied, seen, trashed and the string is
the concatenation of the uppercased first letters of these flags,
as per [1]. Other letters than the ones listed here are ignored.
Also see `mu/flags-to-string'.

\[1\]: http://cr.yp.to/proto/maildir.html"
  (when (/= 0 (length str))
    (let ((flag
	    (case (string-to-char str)
	      (?D   'draft)
	      (?F   'flagged)
	      (?P   'passed)
	      (?R   'replied)
	      (?S   'seen)
	      (?T   'trashed))))
      (append (when flag (list flag))
	(mm/string-to-flags-1 (substring str 1))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(provide 'mm)
