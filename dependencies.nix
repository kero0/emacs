pkgs:
with pkgs;
[
  # basics
  fontconfig
  bashInteractive
  binutils
  curl
  fd
  gitFull
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
  clang-tools

  # grammar
  languagetool

  # spell
  enchant
  (aspellWithDicts (
    dicts: with dicts; [
      en
      en-computers
    ]
  ))

  # latex but mostly for ox-latex
  (
    with texlive;
    texlive.combine {
      inherit
        scheme-small
        biblatex
        dvisvgm
        latexmk
        ;
      inherit
        babel
        capt-of
        environ
        everypage
        float
        fvextra
        needspace
        pdfcol
        siunitx
        standalone
        tcolorbox
        wrapfig
        xcolor
        ;
    }
  )
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

  mu
  msmtp
]
++ lib.optionals (!stdenv.isLinux) [
  coreutils-prefixed
  gnused
]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ])
