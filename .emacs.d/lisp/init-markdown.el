;;; init-markdown.el -- Settings

;;; Commentary:

;; Settings for markdown development

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'markdown-mode)
(require 'markdown-mode)

(setq markdown-command "pandoc")

(provide 'init-markdown)
;;; init-markdown.el ends here
