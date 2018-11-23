;;; init-multiple-cursors.el -- Emacs initialization settings

;;; Commentary:

;; Settings for multiple-cursors package

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'multiple-cursors)

(global-set-key (kbd "C-S-c C-S-c") 'mc/edit-lines)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)

(provide 'init-multiple-cursors)
;;; init-multiple-cursors.el ends here
