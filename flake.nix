{
  description = "Solana development setup with Nix.";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/8b27c1239e5c421a2bbc2c65d52e4a6fbf2ff296";
    flake-parts.url = "github:hercules-ci/flake-parts/f4330d22f1c5d2ba72d3d22df5597d123fdb60a9";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    rust-overlay = {
      url = "github:oxalica/rust-overlay/954582a766a50ebef5695a9616c93b5386418c08";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      flake-parts,
      rust-overlay,
      crane,
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-windows"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        with import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };
        let
          solana-source = callPackage (import ./solana-source.nix) { };
          solana-platform-tools = callPackage (import ./solana-platform-tools.nix) {
            inherit solana-source;
          };
          solana-rust = callPackage (import ./solana-rust.nix) {
            inherit solana-platform-tools;
          };
          solana-cli = callPackage (import ./solana-cli.nix) {
            inherit solana-platform-tools solana-source;
            crane = crane.mkLib pkgs;
          };
          anchor-cli = callPackage (import ./anchor-cli.nix) {
            inherit solana-platform-tools;
            crane = crane.mkLib pkgs;
          };
        in
        {
          devShells.default = mkShell {
            packages = [
              anchor-cli
              solana-cli
              solana-rust
              yarn
              nodejs
            ];
          };

          packages = {
            inherit
              anchor-cli
              solana-cli
              solana-platform-tools
              solana-rust
              ;
          };
        };
    };
}
