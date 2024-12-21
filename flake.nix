{
  description = "A flake for running and building askier";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        lib = nixpkgs.lib;
        pkgs = nixpkgs.legacyPackages.${system};
        ocamlPackages = pkgs.ocamlPackages;
      in
      {
        # Main askier package
        # run with:
        #     nix build
        #     nix run -- args...
        packages = {
          default = self.packages.${system}.askier;

          askier = ocamlPackages.buildDunePackage {
            pname = "askier";
            version = "0.1.0";
            duneVersion = "3";
            src = ./.;

            buildInputs = [
              # OCaml package dependencies go here.
            ];

            strictDeps = true;

          };
        };

        # Flake checks
        #
        #     $ nix flake check
        #
        checks = {
          # Run tests for the `hello` package
          askier =
            let
              # Patches calls to dune commands to produce log-friendly output
              # when using `nix ... --print-build-log`. Ideally there would be
              # support for one or more of the following:
              #
              # In Dune:
              #
              # - have workspace-specific dune configuration files
              #
              # In NixPkgs:
              #
              # - allow dune flags to be set in in `ocamlPackages.buildDunePackage`
              # - alter `ocamlPackages.buildDunePackage` to use `--display=short`
              # - alter `ocamlPackages.buildDunePackage` to allow `--config-file=FILE` to be set
              patchDuneCommand =
                let
                  subcmds = [
                    "build"
                    "test"
                    "runtest"
                    "install"
                  ];
                in
                lib.replaceStrings (lib.lists.map (subcmd: "dune ${subcmd}") subcmds) (
                  lib.lists.map (subcmd: "dune ${subcmd} --display=short") subcmds
                );
            in
            self.packages.${system}.askier.overrideAttrs (oldAttrs: {
              name = "check-${oldAttrs.name}";
              doCheck = true;
              buildPhase = patchDuneCommand oldAttrs.buildPhase;
              checkPhase = patchDuneCommand oldAttrs.checkPhase;
              # installPhase = patchDuneCommand oldAttrs.checkPhase;
            });

          # Check Dune and OCaml formatting
          dune-fmt =
            pkgs.runCommand "check-dune-fmt"
              {
                nativeBuildInputs = [
                  ocamlPackages.dune_3
                  ocamlPackages.ocaml
                  pkgs.ocamlformat
                ];
              }
              ''
                echo "checking dune and ocaml formatting"
                dune build \
                  --display=short \
                  --no-print-directory \
                  --root="${./.}" \
                  --build-dir="$(pwd)/_build" \
                  @fmt
                touch $out
              '';

          # Check documentation generation
          dune-doc =
            pkgs.runCommand "check-dune-doc"
              {
                ODOC_WARN_ERROR = "true";
                nativeBuildInputs = [
                  ocamlPackages.dune_3
                  ocamlPackages.ocaml
                  ocamlPackages.odoc
                ];
              }
              ''
                echo "checking ocaml documentation"
                dune build \
                  --display=short \
                  --no-print-directory \
                  --root="${./.}" \
                  --build-dir="$(pwd)/_build" \
                  @doc
                touch $out
              '';
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            zsh

            # ocaml packages
            ocamlPackages.ocaml
            ocamlPackages.dune_3
            ocamlPackages.utop
            ocamlPackages.findlib
            ocamlPackages.merlin
            ocamlPackages.ocamlformat
          ];
        };
      }
    );
}
