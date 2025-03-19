{
  description = "Solana development setup with Nix.";
  inputs = {
    nixpkgs.url =
      "github:nixos/nixpkgs/c5e2528c7c4ec05ce05a563e3be64f3525b278ad";
    flake-parts.url =
      "github:hercules-ci/flake-parts/f4330d22f1c5d2ba72d3d22df5597d123fdb60a9";
    rust-overlay.url =
      "github:oxalica/rust-overlay/87f0965f9f5b13fca9f38074eee8369dc767550d";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, rust-overlay }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-windows"
      ];
      perSystem = { config, self', inputs', pkgs, system, ... }:
        with import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        let
          solana-source = callPackage (import ./solana-source.nix) { };
          solana-platform-tools =
            callPackage (import ./solana-platform-tools.nix) {
              inherit solana-source;
            };
          solana-rust = callPackage (import ./solana-rust.nix) {
            inherit solana-platform-tools;
          };
          solana-cli = callPackage (import ./solana-cli.nix) {
            inherit solana-platform-tools solana-source;
          };
          anchor-cli = callPackage (import ./anchor-cli.nix) {
            inherit solana-platform-tools;
          };
        in {
          devShells.default = mkShell {
            packages = [ anchor-cli solana-cli solana-rust yarn nodejs ];
          };
        };
    };
}
