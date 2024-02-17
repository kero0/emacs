{ pkgs, is-work, is-personal }:
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
  (ripgrep.override { withPCRE2 = true; })
  wget
  zstd.bin
  zstd

  # grammar
  languagetool

  # spell
  enchant
  (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))

  # latex but mostly for ox-latex
  (with texlive;
    texlive.combine {
      inherit scheme-small biblatex dvisvgm latexmk;
      inherit capt-of environ float fvextra pdfcol siunitx standalone tcolorbox
        wrapfig xcolor;
    })
  ghostscript

  # python
  (python3.withPackages (ps:
    with ps; [
      # default for python
      black
      debugpy
      isort
      pipx
      pyflakes
      python-lsp-server

      # handy for org-mode src blocks
      ipython
      matplotlib
      numpy
      pandas
    ]))
  poetry
] ++ lib.optionals (!stdenv.isLinux) [ coreutils-prefixed gnused ]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ])
++ lib.optionals is-personal [ lilypond mu msmtp ]
