;;; init-html.el -- Settings

;;; Commentary:

;; Settings for HTML development

;;; Code:
;; html-tidy, used by flycheck does not handle django-html well
(add-hook 'mhtml-mode-hook (lambda() (flyspell-mode -1)))
(add-hook 'mhtml-mode-hook (lambda() (flycheck-mode -1)))
(add-hook 'mhtml-mode-hook (lambda() (flymake-mode -1)))

(provide 'init-html)
;;; init-html.el ends here
