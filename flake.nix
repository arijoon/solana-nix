{
  description = "Solana development setup with Nix.";
  inputs = {
    nixpkgs = ./pkgs.nix;
    flake-parts.url = "github:hercules-ci/flake-parts/f4330d22f1c5d2ba72d3d22df5597d123fdb60a9";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin"
      "aarch64-darwin" "x86_64-windows" ];
      perSystem = { config, self', inputs', pkgs, system }: {
        devShells.default = with pkgs; mkShell {
          packages = [
            anchor-cli
            solana-cli
            solana-rust
            yarn
            nodejs
          ];
        };
      };
    };
}
