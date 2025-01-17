;;; init-flyspell.el -- Settings

;;; Commentary:

;; Settings for native package Flyspell, a spell checker

;;; Code:
(require 'flyspell)
(require 'ispell) ;; installed by brew `aspell`
(require 'init-basic) ;; in order to find `aspell` on `exec-path`

(add-hook 'text-mode-hook 'flyspell-mode)

;; Disable flyspell in sub modes of text-mode
(dolist (hook '(change-log-mode-hook log-edit-mode-hook html-mode-hook))
      (add-hook hook (lambda () (flyspell-mode -1))))

(setq flyspell-issue-message-flag nil) ;; performance
(setq flyspell-sort-corrections nil)
(setq ispell-program-name "/usr/local/bin/aspell")

(provide 'init-flyspell)
;;; init-flyspell.el ends here
