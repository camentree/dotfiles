;;; init-basic.el -- Emacs initialiazation settings

;;; Commentary:

;; Settings for default behavior of Emacs

;;; Code:
(require 'init-packages)
(cpiho/require-package 'exec-path-from-shell)
(cpiho/require-package 'column-enforce-mode)

(require 'exec-path-from-shell)
(require 'column-enforce-mode)

;; get env variables from zshenv
;; (setq exec-path-from-shell-arguments nil)
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

(defun cpiho/default-auto-fill ()
  "Set line limit to 80."
  (auto-fill-mode)
  (column-enforce-mode)
  (setq column-enforce-column 80)
  (setq fill-column 80))

(add-hook 'prog-mode-hook 'cpiho/default-auto-fill)
(setq-default show-trailing-whitespace t)

(provide 'init-basic)
;;; init-basic.el ends here
