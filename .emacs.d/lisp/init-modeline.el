;;; init-modeline.el -- Settings

;;; Commentary:

;; Settings for modeline

;;; Code:
(declare-function cpiho/require-package "init-packages")
(cpiho/require-package 'doom-modeline)

(require 'doom-modeline)
(require 'pyvenv)

(defvar virtual-env)
(doom-modeline-def-segment virtual-env
  (concat " " (symbol-value 'pyvenv-virtual-env-name) " "))
  
(doom-modeline-def-modeline
 'custom
 '(bar buffer-info "   " buffer-position)
 '(global major-mode virtual-env vcs flycheck))

(doom-modeline-set-modeline 'custom t)
(doom-modeline-init)

(setq doom-modeline-buffer-file-name-style 'file-name)
(setq doom-modeline-icon nil)
(setq doom-modeline-python-executable nil)

(provide 'init-modeline)
;;; init-modeline.el ends here
