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
;; init-packages should be imported first since many settings file rely on
;; `cpiho/require-package` defined therein
(require 'init-packages)
(require 'init-basic)
(require 'init-themes)
(require 'init-ui)

;; Languages
;; Text
(require 'init-postgres)
(require 'init-python)
(require 'init-html)
(require 'init-markdown)

;; Packages
;; org, mu4e, save frame configurations
(require 'init-ace-window)
(require 'init-flycheck)
(require 'init-flyspell)
(require 'init-helm)
(require 'init-magit)
(require 'init-projectile)
(require 'init-yafolding)

(provide 'init)
;;; init.el ends here
