;;; init-magit.el -- Emacs initialization settings

;;; Commentary:

;; Settings for magit package

;;; Code:
(require 'init-packages)
(cpiho/require-package 'magit)

(global-set-key (kbd "C-c g") 'magit-status)

(provide 'init-magit)
;;; init-magit.el ends here
