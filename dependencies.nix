pkgs:
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

  # python
  (python3.withPackages (ps: with ps; [ black isort pipx python-lsp-server ]))
  poetry

  # mu4e
  mu
  msmtp
] ++ lib.optionals (!stdenv.isLinux) [ coreutils-prefixed gnused ]
++ (if stdenv.isDarwin then [ terminal-notifier ] else [ notify-send ])
