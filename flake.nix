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

        buildInputs = [
          # Add library dependencies here
          ocamlPackages.camlimages
        ];

        nativeBuildInputs = with pkgs; [
          zsh

          # ocaml packages
          ocamlPackages.ocaml
          ocamlPackages.dune_3
          ocamlPackages.utop
          ocamlPackages.findlib
          ocamlPackages.merlin
          ocamlPackages.ocamlformat
        ];

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

            strictDeps = true;

            inherit nativeBuildInputs buildInputs;
          };
        };

        devShells.default = pkgs.mkShell { inherit nativeBuildInputs buildInputs; };
      }
    );
}
