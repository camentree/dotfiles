(cpiho/require-package 'elpy)
(cpiho/require-package 'pyenv-mode)
(cpiho/require-package 'importmagic)
(cpiho/require-package 'jedi)
(cpiho/require-package 'py-autopep8)

;; elpy
(elpy-enable)
(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i --simple-prompt")

;; pyenv-mode
(pyenv-mode)

;; importmagic
(add-hook 'python-mode-hook 'importmagic-mode)

;; jedi
(add-hook 'python-mode-hook 'jedi:setup)
(setq jedi:complete-on-dot t)     

;; py-autopep8
(add-hook 'python-mode-hook 'py-autopep8-enable-on-save)

(provide 'init-python)
