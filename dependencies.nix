pkgs:
with pkgs;
[
  # basics
  fontconfig
  bashInteractive
  curl
  fd
  fontconfig
  gnutls
  imagemagick
  nodePackages.prettier
  (ripgrep.override { withPCRE2 = true; })
  unzip
  wget
  zstd.bin
  zstd

  # lsp
  emacs-lsp-booster

  # spell
  enchant
  (aspellWithDicts (
    dicts: with dicts; [
      en
      en-computers
    ]
  ))

  ghostscript

  # nix
  nil
  nixfmt-rfc-style

  # python
  (python3.withPackages (
    ps: with ps; [
      # default for python
      debugpy
      pipx

      # handy for org-mode src blocks
      ipython
      matplotlib
      numpy
      pandas

      # jupyter notebooks
      jupyter
      jupytext
      nbformat
    ]
  ))
  poetry

  pyright
  ruff

  # jupyter notebooks
  pandoc

  # typst
  typst

  msmtp
]
++ lib.optionals (!stdenv.isLinux) [
  coreutils-prefixed
  gnused
]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ])
