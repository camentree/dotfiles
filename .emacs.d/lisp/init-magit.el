(cpiho/require-package 'magit)

(global-set-key (kbd "C-c g") 'magit-status)

(setq magit-push-always-verify nil)

(provide 'init-magit)
