;;; init.el -- Emacs initialization settings

;;; Commentary:

;; Central location for initialization settings.  Imports
;; the various files necessary for initialization.

;;; Code:
(package-initialize)

(add-to-list 'load-path
	     (expand-file-name "lisp" user-emacs-directory))

(setq custom-file
      (concat (expand-file-name user-emacs-directory) "custom.el"))
(load custom-file 'noerror)

;; General
(require 'init-basic)
(require 'init-packages)
(require 'init-themes)
(require 'init-ui)

;; Languages
;; html, css, js, lisp, markdown, text
(require 'init-postgres)
(require 'init-python)

;; Packages
;; org, mu4e
(require 'init-ace-window)
(require 'init-flycheck)
(require 'init-flyspell)
(require 'init-helm)
(require 'init-magit)
(require 'init-multiple-cursors)
(require 'init-projectile)
(require 'init-yafolding)

(provide 'init)
;;; init.el ends here
