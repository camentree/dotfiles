;;; init-ace.el -- Emacs initializetion settings

;;; Commentary:

;; Settings for ace-window package

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'ace-window)

(global-set-key (kbd "M-o") 'ace-window)
(defvar aw-keys)
(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l))

(provide 'init-ace-window)
;;; init-ace-window.el ends here
