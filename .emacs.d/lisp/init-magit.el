;;; init-magit.el -- Emacs initialization settings

;;; Commentary:

;; Settings for magit package

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'magit)

(global-set-key (kbd "C-c g") 'magit-status)

(defvar magit-push-always-verify)
(setq magit-push-always-verify nil)

(provide 'init-magit)
;;; init-magit.el ends here
