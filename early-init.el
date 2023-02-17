(setq package-enable-at-startup nil)
(when (eq system-type 'darwin)
  (setenv "LIBRARY_PATH" "/opt/homebrew/opt/gcc/lib/gcc/12:/opt/homebrew/opt/libgccjit/lib/gcc/12:/opt/homebrew/opt/gcc/lib/gcc/12/gcc/aarch64-apple-darwin21/12"))

