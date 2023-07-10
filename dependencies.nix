{ pkgs, is-work, is-personal }:
with pkgs;
[
  # basics
  bashInteractive
  binutils
  curlFull
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
  (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))

  # copilot
  nodejs

  # latex but mostly for ox-latex
  (with texlive;
    texlive.combine {
      inherit scheme-small biblatex latexmk;
      inherit capt-of siunitx wrapfig xcolor;
    })

  # julia
  julia-bin

  # python
  (python3.withPackages (ps:
    with ps; [
      # default for python
      black
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

  # rust
  rustup
  rust-analyzer
  cargo

  # haskell; not installed by default because it takes a long time
] ++ lib.optionals (!stdenv.isLinux) [ coreutils-prefixed gnused ]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ libnotify ])

# mu4e
# Both of these are configured outside this repo
# Personally, I configure them using home-manager
++ lib.optionals is-personal [ mu msmtp ]
