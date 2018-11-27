;;; init-markdown.el -- Settings

;;; Commentary:

;; Settings for markdown development

;;; Code:
(require 'init-packages)
(cpiho/require-package 'markdown-mode)

(require 'markdown-mode)
(require 'init-basic)

(setq markdown-command "pandoc")
(add-hook 'markdown-mode-hook 'cpiho/default-auto-fill)

(provide 'init-markdown)
;;; init-markdown.el ends here
