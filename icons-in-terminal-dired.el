;;; icons-in-terminal-dired.el --- Shows icons for each file in dired mode  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Takaaki Ishikawa
;; Copyright (C) 2016  jtbm37

;; Author: Takaaki Ishikawa
;; Version: 0.0.1
;; Keywords: files icons dired
;; Package-Requires: ((emacs "24.4") (icons-in-terminal "0.1.0"))
;; URL: https://github.com/jtbm37/icons-in-terminal-dired

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; To use this package, simply add this to your init.el:
;; (add-hook 'dired-mode-hook 'icons-in-terminal-dired-mode)

;; To manually install, add this to your init.el before the hook mentioned above.
;; (add-to-load-path (expand-file-name "~/path/to/icons-in-terminal-dired"))
;; (load "icons-in-terminal-dired.el")
;;
;; Note: This elisp is mostly copied from `all-the-icons-dired.el'. Thanks to jtbm37!

;;; Code:

(require 'cl-lib)
(require 'dired)
(require 'icons-in-terminal)

(defface icons-in-terminal-dired-dir-face
  '((((background dark)) :foreground "white")
    (((background light)) :foreground "black"))
  "Face for the directory icon"
  :group 'icons-in-terminal-faces)

(defcustom icons-in-terminal-dired-v-adjust 0.01
  "The default vertical adjustment of the icon in the dired buffer."
  :group 'icons-in-terminal
  :type 'number)

(defvar icons-in-terminal-dired-mode)

(defun icons-in-terminal-dired--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((ov (make-overlay (1- pos) pos)))
    (overlay-put ov 'icons-in-terminal-dired-overlay t)
    (overlay-put ov 'after-string string)))

(defun icons-in-terminal-dired--overlays-in (beg end)
  "Get all icons-in-terminal-dired overlays between BEG to END."
  (cl-remove-if-not
   (lambda (ov)
     (overlay-get ov 'icons-in-terminal-dired-overlay))
   (overlays-in beg end)))

(defun icons-in-terminal-dired--overlays-at (pos)
  "Get icons-in-terminal-dired overlays at POS."
  (apply #'icons-in-terminal-dired--overlays-in `(,pos ,pos)))

(defun icons-in-terminal-dired--remove-all-overlays ()
  "Remove all `icons-in-terminal-dired' overlays."
  (save-restriction
    (widen)
    (mapc #'delete-overlay
          (icons-in-terminal-dired--overlays-in (point-min) (point-max)))))

(defun icons-in-terminal-dired--refresh ()
  "Display the icons of files in a dired buffer."
  (icons-in-terminal-dired--remove-all-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (when (dired-move-to-filename nil)
        (let ((file (dired-get-filename 'relative 'noerror)))
          (when file
            (let ((icon (if (file-directory-p file)
                            (icons-in-terminal-icon-for-dir file
                                                            :face 'icons-in-terminal-dired-dir-face
                                                            :v-adjust icons-in-terminal-dired-v-adjust)
                          (icons-in-terminal-icon-for-file file :v-adjust icons-in-terminal-dired-v-adjust))))
              (if (member file '("." ".."))
                  (icons-in-terminal-dired--add-overlay (point) "  \t")
                (icons-in-terminal-dired--add-overlay (point) (concat icon "\t")))))))
      (forward-line 1))))

(defun icons-in-terminal-dired--refresh-advice (fn &rest args)
  "Advice function for FN with ARGS."
  (apply fn args)
  (when icons-in-terminal-dired-mode
    (icons-in-terminal-dired--refresh)))

(defun icons-in-terminal-dired--setup ()
  "Setup `icons-in-terminal-dired'."
  (when (derived-mode-p 'dired-mode)
    (setq-local tab-width 1)
    (advice-add 'dired-readin :around #'icons-in-terminal-dired--refresh-advice)
    (advice-add 'dired-revert :around #'icons-in-terminal-dired--refresh-advice)
    (advice-add 'dired-internal-do-deletions :around #'icons-in-terminal-dired--refresh-advice)
    (advice-add 'dired-insert-subdir :around #'icons-in-terminal-dired--refresh-advice)
    (advice-add 'dired-do-kill-lines :around #'icons-in-terminal-dired--refresh-advice)
    (with-eval-after-load 'dired-narrow
      (advice-add 'dired-narrow--internal :around #'icons-in-terminal-dired--refresh-advice))
    (icons-in-terminal-dired--refresh)))

(defun icons-in-terminal-dired--teardown ()
  "Functions used as advice when redisplaying buffer."
  (advice-remove 'dired-readin #'icons-in-terminal-dired--refresh-advice)
  (advice-remove 'dired-revert #'icons-in-terminal-dired--refresh-advice)
  (advice-remove 'dired-internal-do-deletions #'icons-in-terminal-dired--refresh-advice)
  (advice-remove 'dired-narrow--internal #'icons-in-terminal-dired--refresh-advice)
  (advice-remove 'dired-insert-subdir #'icons-in-terminal-dired--refresh-advice)
  (advice-remove 'dired-do-kill-lines #'icons-in-terminal-dired--refresh-advice)
  (icons-in-terminal-dired--remove-all-overlays))

;;;###autoload
(define-minor-mode icons-in-terminal-dired-mode
  "Display icons-in-terminal icon for each files in a dired buffer."
  :lighter " icons-in-terminal-dired-mode"
  (when (derived-mode-p 'dired-mode)
    (if icons-in-terminal-dired-mode
        (icons-in-terminal-dired--setup)
      (icons-in-terminal-dired--teardown))))

(provide 'icons-in-terminal-dired)
;;; icons-in-terminal-dired.el ends here
