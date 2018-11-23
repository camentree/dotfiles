;;; package -- Summary

;;; Commentary:

;;; Summary

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'flycheck)
(cpiho/require-package 'flycheck-color-mode-line)

;; flycheck
(global-set-key (kbd "C-c 1") 'flycheck-list-errors)

(add-to-list 'display-buffer-alist
             `(,(rx bos "*Flycheck errors*" eos)
              (display-buffer-reuse-window
               display-buffer-in-side-window)
              (side            . bottom)
              (reusable-frames . visible)
              (window-height   . 0.33)))

;; flycheck-color-mode-line
(eval-after-load "flycheck"
  '(add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode))

(add-hook 'prog-mode-hook 'flycheck-mode)
(add-hook 'text-mode-hook 'flycheck-mode)

(provide 'init-flycheck)
;;; init-flycheck.el ends here
