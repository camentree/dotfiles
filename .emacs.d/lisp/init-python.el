(cpiho/require-package 'elpy)
(cpiho/require-package 'pyvenv)
(cpiho/require-package 'importmagic)
(require 'init-flycheck)

;; elpy
(elpy-enable)
(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i --simple-prompt")

;; pyvenv
(setenv "WORKON_HOME" "/Users/camen/miniconda3/envs")
(pyvenv-mode 1)
(global-set-key (kbd "C-c v a") 'pyvenv-workon)
(global-set-key (kbd "C-c v d") 'pyvenv-deactivate)

;; importmagic
(add-hook 'python-mode-hook 'importmagic-mode)

;; jedi -- installed through conda
(add-hook 'python-mode-hook 'jedi:setup)
(add-hook 'python-mode-hook 'jedi:ac-setup)
(setq jedi:complete-on-dot t)

;; py-autopep8 -- installed through conda
(add-hook 'python-mode-hook 'py-autopep8-enable-on-save)

;; flycheck
(add-hook 'python-mode-hook #'flycheck-mode)

(provide 'init-python)
