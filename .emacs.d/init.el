;;; init.el -- Emacs initialization settings

;;; Commentary:

;; Central location for initialization settings.  Imports
;; the various files necessary for initialization.

;;; Code:
(package-initialize)

(add-to-list 'load-path
	     (expand-file-name "lisp" user-emacs-directory))

;; Basic
(require 'init-packages)
(require 'init-basic)
(require 'init-ui)
(require 'init-themes)

;; Languages
;; html, css, js, lisp, markdown, text, flycheck
(require 'init-python)
(require 'init-postgres)

;; Packages
;; org, mu4e
(require 'init-magit)
(require 'init-projectile)
(require 'init-helm)
(require 'init-ace-window)
(require 'init-yafolding)
(require 'init-flycheck)

(setq custom-file
      (concat (expand-file-name user-emacs-directory) "custom.el"))
(load custom-file 'noerror)

(provide 'init)
;;; init.el ends here
