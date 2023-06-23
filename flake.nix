{
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  inputs = {
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs";

    packages-copilot = {
      url = "github:zerolfx/copilot.el";
      flake = false;
    };
    packages-targets = {
      url = "github:noctuid/targets.el";
      flake = false;
    };
    packages-ox-chameleon = {
      url = "github:tecosaur/ox-chameleon";
      flake = false;
    };
  };
  outputs = inputs@{ self, nixpkgs, emacs-overlay, ... }:
    let
      mkTrivialPkg = { pkgs, name, src ? inputs."packages-${name}"
        , buildInputs ? [ ], extraFiles ? [ ] }:
        ((pkgs.trivialBuild {
          inherit buildInputs;
          pname = name;
          ename = name;
          version = "0.0.0";
          src = src;
        }).overrideAttrs (old: {
          installPhase = old.installPhase + (builtins.concatStringsSep "\n"
            (map (s: ''cp -r "${s}" "$LISPDIR"'') extraFiles));
          passthru = (old.passthru or { }) // { treeSitter = true; };
        }));
      f = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ emacs-overlay.overlay ];
          };
          emacs = (pkgs.emacs-pgtk.override {
            withWebP = true;
            withXwidgets = pkgs.stdenv.isDarwin; # only use this on macbook
            withTreeSitter = true;
          }).overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ])
              ++ (pkgs.lib.optional pkgs.stdenv.isDarwin [
                pkgs.darwin.apple_sdk.frameworks.Cocoa
                pkgs.darwin.apple_sdk.frameworks.WebKit
              ]);
          });
          config = pkgs.runCommand "config" { } ''
            mkdir -p $out/
            cp -r ${./.}/. $out
            cd $out/
            ${emacs}/bin/emacs -Q --batch                        \
              --eval "(require 'org)
                      (setq org-use-property-inheritance t)"     \
              --visit="./config.org"                             \
              --funcall org-babel-tangle                         \
              --kill
          '';
          dependencies = import ./dependencies.nix {
            inherit pkgs;
            is-work = false;
            is-personal = true;
          };
        in rec {
          packages.${system}.default = pkgs.emacsWithPackagesFromUsePackage {
            config = ./config.org;
            defaultInitFile = pkgs.writeText "default.el"
              (let deps = nixpkgs.lib.makeBinPath dependencies;
               in ''
                   (add-to-list 'load-path "${./.}/lisp")
                	 (setq my/emacs-dir "${./.}/")
                   (setenv "PATH" (concat (getenv "PATH") ":${deps}"))
              '' + nixpkgs.lib.concatStringsSep "\n"
                (map (s: ''(add-to-list 'exec-path "${s}/bin")'') dependencies)
              + ''
                (load-file "${config}/init.el")
              '');
            package = emacs;
            alwaysEnsure = true;
            alwaysTangle = true;
            extraEmacsPackages = epkgs:
              with epkgs;
              [
                copilot
                engrave-faces
                ox-chameleon
                # FIXME: currently broken in nixpkgs. either wait for fix or find workaround
                treesit-grammars.with-all-grammars
              ] ++ dependencies;
            override = self: super: {
              copilot = (mkTrivialPkg {
                pkgs = self;
                name = "copilot";
                buildInputs = with self; [ dash editorconfig s ];
                extraFiles = [ "dist/" ];
              });
              ox-chameleon = (mkTrivialPkg {
                pkgs = self;
                name = "ox-chameleon";
                buildInputs = with self; [ engrave-faces ];
              });
              targets = (mkTrivialPkg {
                pkgs = self;
                name = "targets";
                buildInputs = with self; [ evil ];
              }).overrideAttrs (old: {
                # fixing a bug in the package when byte compiling
                buildPhase = ''
                  runHook preBuild
                  runHook postBuild
                '';
              });
            };
          };
          devShell.${system} =
            pkgs.mkShell { buildInputs = [ packages.${system}.default ]; };
        };
    in nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate { }
    (map f [ "x86_64-linux" "aarch64-darwin" ]);
}
