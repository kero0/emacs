{
  pkgs,
  is-work,
  is-personal,
}:
with pkgs;
[
  # basics
  bashInteractive
  binutils
  curl
  fd
  gitFull
  gnutls
  imagemagick
  pinentry-emacs
  nodePackages.prettier
  (ripgrep.override { withPCRE2 = true; })
  unzip
  wget
  zstd.bin
  zstd

  # lsp
  emacs-lsp-booster

  # grammar
  languagetool

  # spell
  enchant
  (aspellWithDicts (
    dicts: with dicts; [
      en
      en-computers
      en-science
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
        capt-of
        environ
        float
        fvextra
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
    ]
  ))
  poetry

  pyright
  ruff
]
++ lib.optionals (!stdenv.isLinux) [
  coreutils-prefixed
  gnused
]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ])
++ lib.optionals is-personal [
  lilypond
  mu
  msmtp
]
