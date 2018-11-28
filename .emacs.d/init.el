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
;; must import init-packages first for `cpiho/require-package`
(require 'init-packages)
(require 'init-basic)
(require 'init-themes)
(require 'init-ui)
(require 'init-modeline)

;; Languages
(require 'init-markdown)
(require 'init-postgres)
(require 'init-python)
(require 'init-html)
(require 'init-shell-script)

;; Packages
;; org, mu4e
(require 'init-ace-window)
(require 'init-company)
(require 'init-flycheck)
(require 'init-flyspell)
(require 'init-helm)
(require 'init-magit)
(require 'init-projectile)
(require 'init-yafolding)

(provide 'init)
;;; init.el ends here
