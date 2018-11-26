;;; init-projectile.el -- Emacs initialization settings

;;; Commentary:

;; Settings for projectile and ag packages

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'projectile)
(cpiho/require-package 'ag) ;; necessitates ag found at /usr/local/bin/ag
(require 'projectile)

(setq projectile-enable-caching t)
(setq projectile-completion-system 'helm)

(define-key projectile-mode-map (kbd "C-c p") `projectile-command-map)

(projectile-mode)

(provide 'init-projectile)
;;; init-projectile ends here
