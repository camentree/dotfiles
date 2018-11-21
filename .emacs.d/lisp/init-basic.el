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

