;;; init-basic.el -- Emacs initialiazation settings

;;; Commentary:

;; Settings for default behavior of Emacs

;;; Code:
(declare-function cpiho/require-package "init-packages")

;; get env variables from zshenv
(cpiho/require-package 'exec-path-from-shell)
(defvar exec-path-from-shell-arguments nil)
(exec-path-from-shell-initialize)

;; location for auto-created files
(defconst autosaves-directory
  (expand-file-name "autosaves/"
                    user-emacs-directory))
(setq backup-directory-alist
      (list (cons "."
                  (expand-file-name "backups"
                                    user-emacs-directory))))

;; basic settings
(setq require-final-newline t)
(setq inhibit-startup-message t)
(global-set-key (kbd "C-x f") 'find-file)

(defun default-auto-fill ()
  "Set line limit to 80."
  (auto-fill-mode)
  (setq fill-column 80))

(add-hook 'text-mode-hook 'default-auto-fill)
(add-hook 'prog-mode-hook 'default-auto-fill)

(provide 'init-basic)
;;; init-basic.el ends here
