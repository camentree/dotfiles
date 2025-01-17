;;; init-markdown.el -- Settings

;;; Commentary:

;; Settings for markdown development

;;; Code:
(require 'init-packages)
(require 'init-basic)
(cpiho/require-package 'markdown-mode)

(require 'markdown-mode)

(setq markdown-command "pandoc")
(add-hook 'markdown-mode-hook 'cpiho/default-auto-fill)

(provide 'init-markdown)
;;; init-markdown.el ends here
