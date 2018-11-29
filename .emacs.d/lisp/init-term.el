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
	     (setq-default show-trailing-whitespace nil)
	     (text-scale-decrease 1))))

(provide 'init-term)
;;; init-term.el ends here
