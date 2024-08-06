{
  description = "Flake for tools related to this repository, featuring a nix-shell";

  inputs = {
    # Choose your nix-branch from <https://github.com/NixOS/nixpkgs/branches>,
    # preferably stable ones!
    nixpkgs-repo.url = github:NixOS/nixpkgs/nixos-24.05; # alternatively: nixos-unstable
  };

  outputs = { self, nixpkgs-repo }:
    let
      nixpkgsLib = nixpkgs-repo.lib;

      # Instead of using the subsequent list of self-defined helpers, one could use
      # `flake-utils.url = "github:numtide/flake-utils";` as input which provides
      # similar helpers and keeps them up-to-date.

      # List all systems that should be supported. See
      # <https://github.com/numtide/flake-utils/blob/04c1b180862888302ddfb2e3ad9eaa63afc60cf8/default.nix>
      # for a complete list.
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgsLib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs-repo { inherit system; });
    in {
      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          gdk = pkgs.google-cloud-sdk.withExtraComponents(with pkgs.google-cloud-sdk.components; [
            gke-gcloud-auth-plugin
          ]);
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              self.packages.${system}.gdk
              jq
              kapp
              kubectl
              kubernetes-helm
              opentofu
              terragrunt
              vendir
              ytt
            ];
          };
        });
    };
}