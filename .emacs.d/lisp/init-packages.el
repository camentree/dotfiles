;;; package -- Summary

;;; Commentary:

;;; Summary

;;; Code:
(require 'package)

(setq package-archives '(("elpa"      . "https://elpa.gnu.org/packages/")
                         ("melpa"     . "https://melpa.org/packages/")
                         ("org"       . "http://orgmode.org/elpa/")))

(setq package-menu-async nil)

(defun cpiho/require-package (package)
  "Ensure PACKAGE is installed."
  (if (package-installed-p package)
      t
    (cpiho/package-install package)))

(defun cpiho/package-install (package)
  "Refresh package list and install PACKAGE."
  (package-refresh-contents)
  (package-install package))

(provide 'init-packages)
;;; init-packages.el ends here

