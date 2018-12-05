;;; init-term.el -- Settings

;;; Commentary:

;; Settings for terminal

;;; Code:
(require 'term)

(add-hook 'term-mode-hook
	  (lambda ()
	    (auto-fill-mode -1)
	    (setq tab-width 8)
	    (setq-local show-trailing-whitespace nil)))

(add-hook 'term-line-mode-hook
	  (lambda ()
	    (setq-default cursor-type 'line)))

(add-hook 'term-char-mode-hook
	  (lambda ()
	    (setq-default cursor-type 'bar)))

(provide 'init-term)
;;; init-term.el ends here
