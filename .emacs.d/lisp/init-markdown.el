;;; init-markdown.el -- Settings

;;; Commentary:

;; Settings for markdown development

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'markdown-mode)
(defvar markdown-command "pandoc")
(provide 'init-markdown)
;;; init-markdown.el ends here
