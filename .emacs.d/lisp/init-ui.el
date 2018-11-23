;;; init-ui.el -- Emacs initialization settings

;;; Commentary:

;; Settings for various UI elements in Emacs GUI

;;; Code:
(set-face-attribute 'default nil :font "SF Mono")
(set-face-attribute 'default nil :height 150)
(set-face-attribute 'default nil :weight 'normal)

(tool-bar-mode 0)
(menu-bar-mode 0)
(toggle-scroll-bar 0)

(setq-default cursor-type 'box)
(setq ring-bell-function 'ignore)

(show-paren-mode t)
(display-battery-mode)
(global-set-key (kbd "C-M-=") 'toggle-frame-fullscreen)

(provide 'init-ui)
;;; init-ui.el ends here
