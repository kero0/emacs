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
  };
  outputs = inputs@{ self, nixpkgs, emacs-overlay, ... }:
    let
      mkTrivialPkg =
        { pkgs
        , name
        , src ? inputs."packages-${name}"
        , buildInputs ? [ ]
        , extraFiles ? [ ]
        }:
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
            withXwidgets = true;
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
            ${emacs}/bin/emacs -Q --batch \
              --eval "(require 'org)"     \
              --visit="./config.org"      \
              --funcall org-babel-tangle  \
              --kill
          '';
          dependencies = import ./dependencies.nix pkgs;
        in
          rec {
            packages.${system}.default = pkgs.emacsWithPackagesFromUsePackage {
              config = ./config.org;
              defaultInitFile = pkgs.writeText "default.el" (''
              	            (setq my/emacs-dir "${./.}/")
                            (setenv "PATH" (concat (getenv "PATH") ":${
                              nixpkgs.lib.makeBinPath dependencies
                            }"))
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
                  # FIXME: currently broken in nixpkgs. either wait for fix or find workaround
                  treesit-grammars.with-all-grammars
                ] ++ (import ./dependencies.nix pkgs);
              override = self: super: {
                copilot = (mkTrivialPkg {
                  pkgs = self;
                  name = "copilot";
                  buildInputs = with self; [ dash editorconfig s ];
                  extraFiles = [ "dist/" ];
                });
              };
            };
            devShell.${system} =
              pkgs.mkShell { buildInputs = [ packages.${system}.default ]; };
          };
    in
      nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate { }
        (map f [ "x86_64-linux" "aarch64-darwin" ]);
}
