;;; init-helm.el -- Emacs initialization settings

;;; Commentary:

;; Settings for helm, helm-projectile, helm-ag, and helm-dash packages

;;; Code:
(require 'init-packages)
(require 'init-projectile)
(cpiho/require-package 'helm)
(cpiho/require-package 'helm-projectile)
(cpiho/require-package 'helm-ag)
(cpiho/require-package 'helm-dash)

(require 'helm-mode)
(helm-mode 1)

(defun cpiho/find-init-file (file)
  "Find FILE in .emacs.d/lisp/ directory."
  (interactive "P")
  (helm-find-files-1 (expand-file-name
                      (concat user-emacs-directory "lisp/"))))

(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-s s") 'helm-projectile-ag)
(global-set-key (kbd "C-h a") 'helm-apropos)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-c h p") 'helm-projectile)
(global-set-key (kbd "C-c d") 'cpiho/find-init-file)

(add-to-list 'helm-completing-read-handlers-alist '(find-file))

(helm-projectile-on)

(provide 'init-helm)
;;; init-helm.el ends here
