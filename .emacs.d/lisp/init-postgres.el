;;; init-postgres.el -- Emacs initialization settings

;;; Commentary:

;; Settings for postres development
;; I tried using sqlint (ruby gem) for linting, but it labels an `ORDER BY` as wrong and it is a huge pain to install, so I am not using it

;;; Code:
(require 'sql) ;; native package
(require 'init-basic) ;; in order to find `psql` on `exec-path`

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

(provide 'init-postgres)
;;; init-postgres.el ends here
