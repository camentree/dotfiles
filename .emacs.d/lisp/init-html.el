;;; init-html.el -- Settings

;;; Commentary:

;; Settings for HTML development

;;; Code:
;; html-tidy, used by flycheck does not handle multi-language code well
;; alternative is to use web-mode with handlebars checker, but I cant
;; get it to work
(add-hook 'mhtml-mode-hook (lambda() (flycheck-mode -1)))
(add-hook 'mhtml-mode-hook (lambda() (flymake-mode -1)))

(provide 'init-html)
;;; init-html.el ends here
