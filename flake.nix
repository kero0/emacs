{
  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://kero0.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "kero0.cachix.org-1:uzu0+ZP6R1U1izim/swa3bfyEiS0TElA8hLrGXQGAbA="
    ];
  };
  inputs = {
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    packages-eglot-booster = {
      url = "github:jdtsmith/eglot-booster";
      flake = false;
    };
    packages-ox-chameleon = {
      url = "github:tecosaur/ox-chameleon";
      flake = false;
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      emacs-overlay,
      git-hooks,
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
            inherit src;
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
            config.allowUnfreePredicate =
              pkg:
              builtins.elem (nixpkgs.lib.getName pkg) [
                "copilot-language-server"
              ];
          };
          dependencies = pkgs.symlinkJoin {
            name = "dependnecies";
            paths = import ./dependencies.nix pkgs;
          };
        in
        rec {
          ${system} = import nixpkgs {
            inherit system;
            overlays = [ emacs-overlay.overlay ];
          };
          packages.${system} = rec {
            base = pkgs.emacs-unstable-pgtk;
            fonts = pkgs.symlinkJoin {
              name = "fonts";
              pname = "fonts";
              paths = with pkgs; [
                nerd-fonts.jetbrains-mono
                noto-fonts

                freefont_ttf
                (pkgs.stdenvNoCC.mkDerivation {
                  pname = "Free Serif Avva Shenouda";
                  version = "1.0";
                  src = fetchurl {
                    url = "https://st-takla.org/Dlds/fonts/webfont/FreeSerifAvvaShenouda.ttf";
                    hash = "sha256-KU1AY68Mlht+6dKEgJirKqvGrm/gqV8C6vQoLIfzilY=";
                  };
                  dontConfigure = true;
                  dontUnpack = true;
                  installPhase = ''
                    mkdir -p $out/share/fonts/truetype
                    cp $src $out/share/fonts/truetype/FreeSerifAvvaShenouda.ttf
                  '';
                })
              ];
            };
            emacsWithPkgs = pkgs.emacsWithPackagesFromUsePackage {
              config = ./config.org;
              defaultInitFile = true;
              package = base;
              alwaysEnsure = true;
              alwaysTangle = true;
              extraEmacsPackages = _: [
                dependencies
              ];
              override = self: _: {
                eglot-booster = mkTrivialPkg {
                  pkgs = self;
                  name = "eglot-booster";
                  buildInputs = [ ];
                };
                ox-chameleon = mkTrivialPkg {
                  pkgs = self;
                  name = "ox-chameleon";
                  buildInputs = with self; [ engrave-faces ];
                };
              };
            };
            default = pkgs.symlinkJoin {
              name = "emacs";
              pname = "emacs";
              paths = [ emacsWithPkgs ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for executable in $(ls $out/bin/*); do
                  wrapProgram "$executable" \
                      --set MY_EMACS_PATH ${./.} \
                      --prefix PATH : ${emacsWithPkgs}/bin:${dependencies}/bin \
                      --set MY_TREESIT_PATH "${base.pkgs.treesit-grammars.with-all-grammars}/lib" \
                      --set FONTCONFIG_FILE ${
                        pkgs.makeFontsConf {
                          fontDirectories = [
                            "${fonts}/share/fonts"
                          ];
                        }
                      } \
                      --set OSFONTDIR "${fonts}/share/fonts" \
                      --set TYPST_FONT_PATHS "${fonts}/share/fonts" \
                      --set ASPELL_CONF 'dict-dir ${dependencies}/lib/aspell'
                done
              '';
              inherit (base) meta src version;
            };
          };
          devShells.${system}.default = pkgs.mkShell {
            inherit (self.checks.${system}.pre-commit-check) shellHook;
            buildInputs = [
              self.checks.${system}.pre-commit-check.enabledPackages
            ];
          };
          formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;
          checks.${system} = {
            pre-commit-check = git-hooks.lib.${system}.run {
              src = ./.;
              hooks = {
                deadnix.enable = true;
                statix = {
                  enable = true;
                  settings = {
                    ignore = [
                      ".direnv"
                    ];
                  };
                };

                nixfmt-rfc-style = {
                  enable = true;
                  package = self.formatter.${system};
                };
              };
            };
            package = self.packages.${system}.default;
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
