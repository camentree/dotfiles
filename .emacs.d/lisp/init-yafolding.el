(cpiho/require-package 'yafolding)

(define-key yafolding-mode-map (kbd "C-M-\\") 'yafolding-toggle-all)
(define-key yafolding-mode-map (kbd "C-S-\\") 'yafolding-hide-parent-element)
(define-key yafolding-mode-map (kbd "C-\\") 'yafolding-toggle-element)

(add-hook 'prog-mode-hook
          (lambda () (yafolding-mode)))

(lambda ()
    (yafolding-show-all)
    (delete-trailing-whitespace))

(provide 'init-yafolding)
