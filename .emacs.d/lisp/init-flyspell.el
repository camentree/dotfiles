;;; init-flyspell.el -- Settings

;;; Commentary:

;; Settings for native package Flyspell, a spell checker

;;; Code:
(require 'flyspell) ;; native package; relies on `ispell`
;; flyspell relies on `ispell` which ships with the brew
;; package `aspell`, which it finds at /usr/local/bin/aspell
(require 'ispell)
(require 'init-basic) ;; in order to find `aspell` on `exec-path`

(add-hook 'prog-mood-hook 'flyspell-prog-mode)
(add-hook 'text-mode-hook 'flyspell-mode)

;; disable flyspell in sub modes of text-mode
(dolist (hook '(change-log-mode-hook log-edit-mode-hook))
      (add-hook hook (lambda () (flyspell-mode -1))))

(setq flyspell-issue-message-flag nil) ;; performance
(setq flyspell-sort-corrections nil)

(provide 'init-flyspell)
;;; init-flyspell.el ends here
