{
  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    sandbox = false; # sandbox causing issues on darwin
  };
  inputs = {
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    packages-eglot-booster = {
      url = "github:jdtsmith/eglot-booster";
      flake = false;
    };
    packages-targets = {
      url = "github:noctuid/targets.el";
      flake = false;
    };
    packages-org-pretty-table = {
      url = "github:Fuco1/org-pretty-table";
      flake = false;
    };
    packages-org-src-context = {
      url = "github:karthink/org-src-context";
      flake = false;
    };
    packages-ox-chameleon = {
      url = "github:tecosaur/ox-chameleon";
      flake = false;
    };

    # temporary until fix is merged upstream
    packages-org-msg = {
      url = "github:danielfleischer/org-msg/1.12";
      flake = false;
    };
    packages-emacs-jupyter = {
      url = "github:emacs-jupyter/jupyter";
      flake = false;
    };
    packages-zmq = {
      url = "github:nnicandro/emacs-zmq";
      flake = false;
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      emacs-overlay,
      pre-commit-hooks,
      ...
    }:
    let
      mkTrivialPkg =
        {
          pkgs,
          name,
          src ? inputs."packages-${name}",
          buildInputs ? [ ],
          extraFiles ? [ ],
        }:
        (
          (pkgs.trivialBuild {
            inherit buildInputs;
            pname = name;
            ename = name;
            version = "0.0.0";
            src = src;
          }).overrideAttrs
          (old: {
            installPhase =
              old.installPhase
              + (builtins.concatStringsSep "\n" (map (s: ''cp -r "${s}" "$LISPDIR"'') extraFiles));
            passthru = (old.passthru or { }) // {
              treeSitter = true;
            };
          })
        );
      f =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ emacs-overlay.overlay ];
          };
          basemacs = (import nixpkgs { inherit system; }).emacs29-pgtk;
          dependencies = pkgs.symlinkJoin {
            name = "dependnecies";
            paths = import ./dependencies.nix {
              inherit pkgs;
              is-work = false;
              is-personal = true;
            };
          };
          emacs = pkgs.symlinkJoin rec {
            name = "emacs";
            paths = [ basemacs ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram "$out/bin/emacs" \
                  --prefix PATH : $out/bin:${dependencies}/bin \
                  --set MY_TREESIT_PATH "${basemacs.pkgs.treesit-grammars.with-all-grammars}/lib" \
                  --prefix EMACSLOADPATH : "${dependencies}/share/emacs/site-lisp":$out/share/emacs/${version}/lisp \
                  --set FONTCONFIG_FILE ${
                    pkgs.makeFontsConf {
                      fontDirectories = with pkgs; [
                        julia-mono
                        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
                      ];
                    }
                  } \
                  --set ASPELL_CONF 'dict-dir ${dependencies}/lib/aspell'
            '';
            inherit (basemacs) meta src version;
          };
          config' = pkgs.runCommand "config" { } ''
            mkdir -p $out/
            cp -r ${./.}/. $out
            cd $out/
            ${basemacs}/bin/emacs -Q --batch                     \
              --eval "(require 'org)
                      (setq org-use-property-inheritance t)"     \
              --visit="./config.org"                             \
              --funcall org-babel-tangle                         \
              --kill
          '';
        in
        rec {
          ${system} = import nixpkgs {
            inherit system;
            overlays = [ emacs-overlay.overlay ];
          };
          packages.${system}.default =
            (pkgs.emacsWithPackagesFromUsePackage {
              config = "${config'}/default.el";
              defaultInitFile = true;
              package = emacs;
              alwaysEnsure = true;
              alwaysTangle = true;
              extraEmacsPackages =
                epkgs: with epkgs; [
                  engrave-faces
                  ox-chameleon
                  dependencies
                ];
              override = self: super: {
                eglot-booster = (
                  mkTrivialPkg {
                    pkgs = self;
                    name = "eglot-booster";
                    buildInputs = with self; [ ];
                  }
                );
                org-pretty-table = (
                  mkTrivialPkg {
                    pkgs = self;
                    name = "org-pretty-table";
                    buildInputs = with self; [ ];
                  }
                );
                org-src-context = (
                  mkTrivialPkg {
                    pkgs = self;
                    name = "org-src-context";
                    buildInputs = with self; [ ];
                  }
                );
                ox-chameleon = (
                  mkTrivialPkg {
                    pkgs = self;
                    name = "ox-chameleon";
                    buildInputs = with self; [ engrave-faces ];
                  }
                );
                targets =
                  (mkTrivialPkg {
                    pkgs = self;
                    name = "targets";
                    buildInputs = with self; [ evil ];
                  }).overrideAttrs
                    (old: {
                      # fixing a bug in the package when byte compiling
                      buildPhase = ''
                        runHook preBuild
                        runHook postBuild
                      '';
                    });
                jupyter =
                  (mkTrivialPkg {
                    pkgs = self;
                    name = "emacs-jupyter";
                    buildInputs = with self; [
                      simple-httpd
                      websocket
                      zmq
                    ];
                  }).overrideAttrs
                    (old: {
                      buildPhase = ''
                        runHook preBuild
                        runHook postBuild
                      '';
                    });
                zmq =
                  (mkTrivialPkg {
                    pkgs = self;
                    name = "zmq";
                    buildInputs = with self; [ websocket ];
                  }).overrideAttrs
                    (old: {
                      buildPhase = ''
                        runHook preBuild
                        runHook postBuild
                      '';
                    });
                org-msg = super.melpaPackages.org-msg.overrideAttrs (old: {
                  src = inputs.packages-org-msg;
                });
              };
            }).overrideAttrs
              (old: {
                name = "emacs";
              });
          devShell.${system} = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = [
              packages.${system}.default
              self.checks.${system}.pre-commit-check.enabledPackages
            ];
          };
          formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
          checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt = {
                enable = true;
                package = self.formatter.${system};
              };
            };
          };
        };
    in
    nixpkgs.lib.foldl nixpkgs.lib.recursiveUpdate { } (
      map f [
        "x86_64-linux"
        "aarch64-darwin"
      ]
    );
}
