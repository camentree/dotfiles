;;; init-helm.el -- Emacs initialization settings

;;; Commentary:

;; Settings for helm, helm-projectile, helm-ag, and helm-dash packages

;;; Code:
(declare-function cpiho/require-package "init-packages")

(require 'projectile)
(cpiho/require-package 'helm)
(cpiho/require-package 'helm-projectile)
(cpiho/require-package 'helm-ag)
(cpiho/require-package 'helm-dash)

(helm-mode 1)

(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-s s") 'helm-projectile-ag)

;; apropos override
(global-set-key (kbd "C-h a") 'helm-apropos)

;; Don't use helm for standard find-file. I keep `C-x f` available
;; as find-file with standard completion.
(add-to-list 'helm-completing-read-handlers-alist '(find-file))

;; old buffer switching
(global-set-key (kbd "C-c h b") 'switch-to-buffer)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "M-X") 'execute-extended-command)
(global-set-key (kbd "C-c C-c M-x") 'execute-extended-command)

;;; helm projectile integration
(global-set-key (kbd "C-c h p") 'helm-projectile)
(helm-projectile-on)

;; undo the projectile-ag remap
(define-key projectile-mode-map [remap projectile-ag] nil)
(define-key projectile-mode-map (kbd "C-c p s a") #'helm-projectile-ag)

(defun cpiho/find-init-file (file)
  "Find FILE in .emacs.d/lisp/ directory."
  (interactive "P")
  (helm-find-files-1 (expand-file-name
                      (concat user-emacs-directory "lisp/"))))

(global-set-key (kbd "C-c d") 'cpiho/find-init-file)

(provide 'init-helm)
;;; init-helm.el ends here
