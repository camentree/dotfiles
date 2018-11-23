;;; init-python -- Emacs initialization settings

;;; Commentary:

;; Seetings for python development in Emacs

;;; Code:

(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'elpy)
(cpiho/require-package 'pyvenv)

(require 'flycheck)

;; elpy
(elpy-enable)
;; TODO think about using Jupyter
(defvar python-shell-interpreter) ;; for some reason I can't set the value here or elpy-config won't configure correctly
(defvar python-shell-interpreter-args) ;; for some reason I can't set the value here or elpy-config won't configure correctly
(setq python-shell-interpreter "ipython"
      python-shell-interpreter-args "-i --simple-prompt")

;; pyvenv
(setenv "WORKON_HOME" "/Users/camen/miniconda3/envs")
(pyvenv-mode 1)
(pyvenv-workon "camen3.6")
(global-set-key (kbd "C-c v a") 'pyvenv-workon)
(global-set-key (kbd "C-c v d") 'pyvenv-deactivate) ;; I have to press another key after "d" for this to take effect. It might just be that the mode line doesn't update?

(provide 'init-python)
;;; init-python.el ends here
