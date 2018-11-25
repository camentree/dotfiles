;;; init-projectile.el -- Emacs initialization settings

;;; Commentary:

;; Settings for projectile and ag packages

;;; Code:
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'projectile)
(cpiho/require-package 'ag) ;; necessitates ag found at /usr/local/bin/ag

(defvar projectile-keymap-prefix (kbd "C-c p"))
(defvar projectile-enable-caching t)

(projectile-mode)

(defvar projectile-completion-system 'helm)

(defun cpiho/projectile-init ()
  "My projectile initialization."

  ;; I don't like that projectile-ag doesn't take a regexp. And even
  ;; running it with C-u doesn't seem to work?
  (defvar projectile-mode-map)
  (define-key projectile-mode-map (kbd "C-c p s s") #'ag-project-regexp))

(add-hook 'projectile-mode-hook #'cpiho/projectile-init)

(provide 'init-projectile)
;;; init-projectile ends here
