(cpiho/require-package 'elpy)
(cpiho/require-package 'pyvenv)
(require 'init-flycheck)

;; elpy
(elpy-enable)
(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i --simple-prompt")

;; pyvenv
(setenv "WORKON_HOME" "/Users/camen/miniconda3/envs")
(add-hook 'python-mode-hook #'pyvenv-mode)
(global-set-key (kbd "C-c v a") 'pyvenv-workon)
(global-set-key (kbd "C-c v d") 'pyvenv-deactivate) ;; I have to press another key after "d" for this to take effect

;; flycheck
(add-hook 'python-mode-hook #'flycheck-mode)

(provide 'init-python)
