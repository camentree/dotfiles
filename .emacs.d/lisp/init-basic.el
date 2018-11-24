;;; init-basic.el -- Emacs initialiazation settings

;;; Commentary:

;; Settings for default behavior of Emacs

;;; Code:
(require 'init-packages)
(declare-function cpiho/require-package "init-packages")

(cpiho/require-package 'exec-path-from-shell)
;; exec-path-from-shell -- https://github.com/purcell/exec-path-from-shell#motivation
(exec-path-from-shell-initialize)

(defconst autosaves-directory
  (expand-file-name "autosaves/"
                    user-emacs-directory))

(setq backup-directory-alist
      (list (cons "."
                  (expand-file-name "backups"
                                    user-emacs-directory))))

(setq require-final-newline t)
(setq inhibit-startup-message t)

(global-set-key (kbd "C-x f") 'find-file)

(provide 'init-basic)
;;; init-basic.el ends here
