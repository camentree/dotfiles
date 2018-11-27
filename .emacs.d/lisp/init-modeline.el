;;; init-modeline.el -- Settings

;;; Commentary:

;; Settings for modeline

;;; Code:
(require 'init-packages)
(cpiho/require-package 'doom-modeline)

(require 'doom-modeline)
(require 'pyvenv)

(doom-modeline-def-segment virtual-env
  (concat "/" (symbol-value 'pyvenv-virtual-env-name) " "))

(doom-modeline-def-modeline
 'custom
 '(bar buffer-info "   " buffer-position)
 '(major-mode virtual-env vcs flycheck global))

(doom-modeline-set-modeline 'custom t)
(doom-modeline-init)

(setq doom-modeline-buffer-file-name-style 'file-name)
(setq doom-modeline-icon nil)
(setq doom-modeline-python-executable nil)

(display-battery-mode)
(setq-default display-time-format " %k:%M]")
(setq-default display-time-default-load-average nil)
(display-time-mode)

(provide 'init-modeline)
;;; init-modeline.el ends here
