;;; init-postgres.el -- Emacs initialization settings

;;; Commentary:

;; Settings for postres development

;;; Code:
(add-hook 'sql-mode-hook
      (lambda ()
        (setq indent-tabs-mode t)
        (setq tab-width 4)))

(defun cpiho/postgres-scratch ()
  "Create a new scratch buffer set up for postgres."
  (interactive)
  (let ((postgres-buffer (get-buffer-create "*postgres-scratch*")))
    (with-current-buffer postgres-buffer
      (sql-mode)
      (sql-highlight-postgres-keywords)
      (sql-set-sqli-buffer))
    (split-window-sensibly)
    (switch-to-buffer postgres-buffer)))

(unless (locate-file "psql" exec-path)
  (let ((mac-psql "/usr/local/bin/psql"))
    (if (file-exists-p mac-psql)
        (defvar sql-postgres-program mac-psql))))

(provide 'init-postgres)
;;; init-postgres.el ends here
