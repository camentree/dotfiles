(setq projectile-keymap-prefix (kbd "C-c p"))

(cpiho/require-package 'projectile)
(cpiho/require-package 'ag)

(projectile-global-mode)

(setq projectile-enable-caching t)

(setq projectile-completion-system 'helm)

(defun cpiho/projectile-init ()
  "My projectile initialization."

  ;; I don't like that projectile-ag doesn't take a regexp. And even
  ;; running it with C-u doesn't seem to work?
  (define-key projectile-mode-map (kbd "C-c p s s") #'ag-project-regexp)
  )

(add-hook 'projectile-mode-hook #'cpiho/projectile-init)

(provide 'init-projectile)
