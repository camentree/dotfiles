;;; init-term.el -- Settings

;;; Commentary:

;; Settings for terminal

;;; Code:
(require 'term)

(add-hook 'term-mode-hook
	  (function
	   (lambda ()
	     (auto-fill-mode -1)
	     (setq tab-width 8)
	     (setq-default show-trailing-whitespace nil))))

(provide 'init-term)
;;; init-term.el ends here
