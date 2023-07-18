;;; package --- Misha's Emacs configuration -*- lexical-binding: t -*-

;;; Commentary:

;; This is a rookie Emacs configuration

;;; Code:

(require 'compile)
(defvar native-comp-deferred-compilation-deny-list ())

;; Set customizations path
(setq custom-file "~/.emacs.d/emacs-custom.el")
(load custom-file)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(setq xterm-extra-capabilities '(getSelection setSelection reportBackground))

(use-package straight
  :custom (straight-use-package-by-default t))

(use-package markdown-mode
  :hook (markdown-mode . (lambda () (set-fill-column 120))))

(use-package magit)

(use-package exec-path-from-shell
  :init
  (when (or (memq window-system '(mac ns)) (daemonp))
    (exec-path-from-shell-initialize)))

(use-package vertico
  ;; Special recipe to load extensions conveniently
  :straight (vertico :files (:defaults "extensions/*")
                     :includes (vertico-indexed
                                vertico-flat
                                vertico-grid
                                vertico-mouse
                                vertico-quick
                                vertico-buffer
                                vertico-repeat
                                vertico-reverse
                                vertico-directory
                                vertico-multiform
                                vertico-unobtrusive
                                ))
  :config
  (vertico-mode))

;; Persist history over Emacs restarts. Vertico sorts by history position.
(use-package savehist
  :init
  (savehist-mode))

(use-package company
  :config
  (setq company-idle-delay 0.3)
  (global-company-mode t)
  ;; the following stops company from using the orderless completion style
  ;; makes company much more useful
  ;; Source: https://www.patrickdelliott.com/emacs.d/
  (define-advice company-capf
      (:around (orig-fun &rest args) set-completion-styles)
    (let ((completion-styles '(basic partial-completion)))
      (apply orig-fun args))))

;; See https://emacs.stackexchange.com/a/48585/
(defun ask-before-closing ()
  "Replace `save-buffers-kill-terminal' to make sure the server isn't killed."
  (interactive)
  (if (daemonp)
      (if (y-or-n-p (format "Really exit Emacs? "))
          (save-buffers-kill-terminal)
        (message "Canceled frame close!"))
    (save-buffers-kill-terminal)))

;; A few more useful configurations...
(use-package emacs
  :bind (("C-x C-c" . 'ask-before-closing))
  :straight nil
  :hook ((emacs-lisp-mode . flymake-mode))
  :init
  ;; Do not allow the cursor in the minibuffer prompt
  ;; (setq minibuffer-prompt-properties
  ;;       '(read-only t cursor-intangible t face minibuffer-prompt))
  ;; (add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

  ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
  ;; Vertico commands are hidden in normal buffers.
  ;; (setq read-extended-command-predicate
  ;;       #'command-completion-default-include-p)

  ;; Enable recursive minibuffers
  (setq enable-recursive-minibuffers t
        column-number-mode t
        ;; Relative line numbers
        display-line-numbers-type 'relative
        auto-save-file-name-transforms
        `((".*" ,(concat user-emacs-directory "auto-save/") t))
        backup-directory-alist
        `(("." . ,(expand-file-name
                   (concat user-emacs-directory "backups"))))
        isearch-wrap-pause 'no-ding
        visible-bell t
        save-interprogram-paste-before-kill t)
  (setq-default indent-tabs-mode nil)
  (global-display-line-numbers-mode)
  (windmove-default-keybindings)
  (menu-bar-mode -1)
  (tool-bar-mode -1))

(use-package flyspell
  :straight nil
  :config
  (setq ispell-program-name "aspell")
  (setq ispell-list-command "--list")
  (add-hook 'text-mode-hook 'flyspell-mode)
  (add-hook 'prog-mode-hook 'flyspell-prog-mode)
  (setq flyspell-issue-message-flag nil)
  (unbind-key "C-." flyspell-mode-map))

;; Optionally use the `orderless' completion style.
(use-package orderless
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles basic partial-completion)))))

;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Either bind `marginalia-cycle' globally or only in the minibuffer
  ;; :bind (("M-A" . marginalia-cycle)
  ;;        :map minibuffer-local-map
  ;;     ("M-A" . marginalia-cycle))

  ;; The :init configuration is always executed (Not lazy!)
  :init

  ;; Must be in the :init section of use-package such that the mode gets
  ;; enabled right away. Note that this forces loading the package.
  (marginalia-mode))

;; Example configuration for Consult
(use-package consult
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (;; C-c bindings (mode-specific-map)
         ("C-c h" . consult-history)
         ("C-c m" . consult-mode-command)
         ("C-c k" . consult-kmacro)
         ;; C-x bindings (ctl-x-map)
         ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
         ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
         ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
         ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
         ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
         ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
         ;; Custom M-# bindings for fast register access
         ("M-#" . consult-register-load)
         ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
         ("C-M-#" . consult-register)
         ;; Other custom bindings
         ("M-y" . consult-yank-pop)                ;; orig. yank-pop
         ;; M-g bindings (goto-map)
         ("M-g e" . consult-compile-error)
         ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
         ("M-g g" . consult-goto-line)             ;; orig. goto-line
         ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
         ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
         ("M-g m" . consult-mark)
         ("M-g k" . consult-global-mark)
         ("M-g i" . consult-imenu)
         ("M-g I" . consult-imenu-multi)
         ;; M-s bindings (search-map)
         ("M-s d" . consult-find)
         ("M-s D" . consult-locate)
         ("M-s g" . consult-grep)
         ("M-s G" . consult-git-grep)
         ("M-s r" . consult-ripgrep)
         ("M-s l" . consult-line)
         ("M-s L" . consult-line-multi)
         ("M-s k" . consult-keep-lines)
         ("M-s u" . consult-focus-lines)
         ;; Isearch integration
         ("M-s e" . consult-isearch-history)
         :map isearch-mode-map
         ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
         ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
         ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
         ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
         ;; Minibuffer history
         :map minibuffer-local-map
         ("M-s" . consult-history)                 ;; orig. next-matching-history-element
         ("M-r" . consult-history))                ;; orig. previous-matching-history-element

  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Configure other variables and modes in the :config section,
  ;; after lazily loading the package.
  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key (kbd "M-."))
  ;; (setq consult-preview-key (list (kbd "<S-down>") (kbd "<S-up>")))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key (kbd "M-.")
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  ; (setq consult-narrow-key "<") ;; (kbd "C-+")

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; By default `consult-project-function' uses `project-root' from project.el.
  ;; Optionally configure a different project root function.
  ;; There are multiple reasonable alternatives to chose from.
  ;;;; 1. project.el (the default)
  ;; (setq consult-project-function #'consult--default-project--function)
  ;;;; 2. projectile.el (projectile-project-root)
  ;; (autoload 'projectile-project-root "projectile")
  ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;;;; 3. vc.el (vc-root-dir)
  ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  ;;;; 4. locate-dominating-file
  ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
)

(use-package embark
  :bind
  (("C-." . embark-act)         ;; pick some comfortable binding
   ("C-;" . embark-dwim)        ;; good alternative: M-.
   ("C-h B" . embark-bindings)) ;; alternative for `describe-bindings'

  :init

  ;; Optionally replace the key help with a completing-read interface
  (setq prefix-help-command #'embark-prefix-help-command)

  :config

  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Consult users will also want the embark-consult package.
(use-package embark-consult
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; lsp-mode
(use-package lsp-mode
  :straight (lsp-mode :type git :host github :repo "emacs-lsp/lsp-mode")
  :config
  (setq lsp-inlay-hint-enable t)
  :hook (lsp-inlay-hints-mode . lsp-mode))

;; Enhanced Rust mode with automatic LSP support.
(use-package rustic
  :straight (rustic :type git :host github :repo "brotzeit/rustic"
                    :fork (:protocol ssh
                                     :host github
                                     :branch "cargo-outdated-workspace"
                                     :repo "mishazharov/rustic"))
  :config (setq
           rustic-format-on-save nil
           rustic-analyzer-command '("~/.rustup/toolchains/stable-x86_64-unknown-linux-gnu/bin/rust-analyzer")
           eldoc-echo-area-use-multiline-p nil)
  :hook ((rust-ts-mode . rustic-mode)))

;; Keeping this around *just in case eglot turns evil*
;;
;; (use-package eglot
;;   :straight nil
;;   :config (add-to-list 'eglot-stay-out-of 'flymake 'eldoc)
;; (setq eglot-send-changes-idle-time (* 60 60)))

; From https://www.nathanfurnal.xyz/posts/building-tree-sitter-langs-emacs/
(use-package treesit
  :straight nil
  :commands (treesit-install-language-grammar nf/treesit-install-all-languages)
  :init
  (setq treesit-language-source-alist
        '((bash . ("https://github.com/tree-sitter/tree-sitter-bash"))
          (c . ("https://github.com/tree-sitter/tree-sitter-c"))
          (cpp . ("https://github.com/tree-sitter/tree-sitter-cpp"))
          (css . ("https://github.com/tree-sitter/tree-sitter-css"))
          (go . ("https://github.com/tree-sitter/tree-sitter-go"))
          (html . ("https://github.com/tree-sitter/tree-sitter-html"))
          (javascript . ("https://github.com/tree-sitter/tree-sitter-javascript"))
          (json . ("https://github.com/tree-sitter/tree-sitter-json"))
          (lua . ("https://github.com/Azganoth/tree-sitter-lua"))
          (make . ("https://github.com/alemuller/tree-sitter-make"))
          (ocaml . ("https://github.com/tree-sitter/tree-sitter-ocaml" "master" "ocaml/src"))
          (python . ("https://github.com/tree-sitter/tree-sitter-python"))
          (php . ("https://github.com/tree-sitter/tree-sitter-php"))
          (typescript . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src"))
          (tsx . ("https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src"))
          (ruby . ("https://github.com/tree-sitter/tree-sitter-ruby"))
          (rust . ("https://github.com/tree-sitter/tree-sitter-rust"))
          (sql . ("https://github.com/DerekStride/tree-sitter-sql"))
          (toml . ("https://github.com/tree-sitter/tree-sitter-toml"))
          (yaml . ("https://github.com/ikatyang/tree-sitter-yaml"))
          (zig . ("https://github.com/GrayJack/tree-sitter-zig"))
          (cmake . ("https://github.com/uyha/tree-sitter-cmake"))))
  :config
  (defun nf/treesit-install-all-languages ()
    "Install all languages specified by `treesit-language-source-alist'."
    (interactive)
    (let ((languages (mapcar 'car treesit-language-source-alist)))
      (dolist (lang languages)
        (treesit-install-language-grammar lang)
        (message "`%s' parser was installed." lang)
        (sit-for 0.75)))))

(use-package yaml-ts
  :straight nil
  :mode (("\\.yaml\\'" . yaml-ts-mode)
         ("\\.yml\\'" . yaml-ts-mode)))

(use-package python-mode
  :straight nil
  :mode (("\\.py\\'" . python-mode)))

(use-package cmake-ts
  :straight nil
  :mode (("\\.cmake\\'" . cmake-ts-mode)
         ("\\CMakeLists.txt\\'" . cmake-ts-mode))
  :config
  (setq indent-tabs-mode nil))

(use-package diff-hl
  :straight (diff-hl :type git :host github :repo "dgutov/diff-hl")
  :config
  (global-diff-hl-mode)
  (add-hook 'magit-pre-refresh-hook 'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook 'diff-hl-magit-post-refresh)
  (add-hook 'dired-mode-hook (lambda () (progn (diff-hl-dired-mode) (revert-buffer)))))

(use-package web-mode
  :straight (web-mode :type git :host github :repo "fxbois/web-mode")
  :mode (("\\.svelte\\'" . web-mode)
         ("\\.ts\\'" . web-mode)))

(use-package wgrep
  :straight (wgrep :type git :host github :repo "mhayashi1120/Emacs-wgrep"))

(use-package dtrt-indent
  :straight (dtrt-indent :type git :host github :repo "jscheid/dtrt-indent"))

(use-package projectile
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map))

(use-package lsp-pyright
  :ensure t
  :hook (python-mode . (lambda ()
                          (require 'lsp-pyright)
                          (lsp))))

(defun c-mode-indentation-hook ()
  (c-set-offset 'statement-block-intro '++)
  (c-set-offset 'defun-block-intro '++))
(add-hook 'c-mode-common-hook 'c-mode-indentation-hook)

(let ((personal-settings (concat (file-name-directory user-init-file) "personal.el")))
 (when (file-exists-p personal-settings)
   (load-file personal-settings)))

(provide 'init)
;;; init.el ends here
