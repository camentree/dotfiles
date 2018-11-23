;;; init-yafolding.el -- Emacs initialization settings

;;; Commentary:

;; Settings for yafolding package

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'yafolding)

(define-key yafolding-mode-map (kbd "C-M-\\") 'yafolding-toggle-all)
(define-key yafolding-mode-map (kbd "C-S-\\") 'yafolding-hide-parent-element)
(define-key yafolding-mode-map (kbd "C-\\") 'yafolding-toggle-element)

(add-hook 'prog-mode-hook
          (lambda () (yafolding-mode)))

(provide 'init-yafolding)
;;; init-yafolding.el ends here
