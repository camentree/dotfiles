;;; init-company.el -- Settings

;;; Commentary:

;; Settings for company-mode

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'company)
(require 'company)

(add-hook 'after-init-hook 'global-company-mode)
(global-set-key (kbd "M-SPC") 'company-complete)
(setq company-idle-delay 0.5)
(setq company-tooltip-align-annotations t)

(provide 'init-company)
;;; init-company.el ends here
