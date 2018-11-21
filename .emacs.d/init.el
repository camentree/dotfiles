(package-initialize)

(add-to-list 'load-path
	     (expand-file-name "lisp" user-emacs-directory))

;; Basic
(require 'init-packages)
(require 'init-basic)
(require 'init-ui)
(require 'init-themes)

;; Languages
;; python, postgres, html, css, js, lisp, markdown, text
(require 'init-python)

;; Packages
;; projectile, helm, multiple cursors, org, 
(require 'init-magit)
(require 'init-projectile)
(require 'init-helm)

(setq custom-file
      (concat (expand-file-name user-emacs-directory) "custom.el"))
(load custom-file 'noerror)

