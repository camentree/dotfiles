;;; init-python -- Emacs initialization settings

;;; Commentary:

;; Seetings for python development in Emacs

;;; Code:
(require 'init-packages)
(require 'init-flycheck)
(require 'init-blacken)
(cpiho/require-package 'elpy)
(cpiho/require-package 'pyvenv)

(require 'elpy)

;; elpy
(setq elpy-modules
   (quote
    (elpy-module-eldoc elpy-module-yasnippet elpy-module-sane-defaults)))
(elpy-enable)

;(setq python-shell-interpreter "jupyter"
;      python-shell-interpreter-args "console --simple-prompt"
;      python-shell-prompt-detect-failure-warning nil)
;(add-to-list 'python-shell-completion-native-disabled-interpreters
					;             "jupyter")
(setq python-shell-interpreter "ipython"
        python-shell-interpreter-args "--simple-prompt -i")

;; pyvenv
(setenv "WORKON_HOME" (substitute-in-file-name "$HOME/miniconda3/envs"))
(pyvenv-mode 1)
(pyvenv-workon "camen3.6")
(global-set-key (kbd "C-c v a") 'pyvenv-workon)
(global-set-key (kbd "C-c v d") 'pyvenv-deactivate)

;; black -- use this instead of elpy for more configuration ability
(setq blacken-allow-py36 t)
(setq blacken-line-length 'fill)
(add-hook 'python-mode-hook 'blacken-mode)

;; flycheck
(add-hook 'python-mode-hook #'(lambda () (setq flycheck-checker 'python-pylint)))

(provide 'init-python)
;;; init-python.el ends here
