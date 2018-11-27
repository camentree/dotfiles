;;; init-themes.el -- Emacs initialization settings

;;; Commentary:

;; Settings for Emacs GUI themes

;;; Code:
(require 'init-packages)
(cpiho/require-package 'material-theme)

(load-theme 'material t)

(provide 'init-themes)
;;; init-themes.el ends here
