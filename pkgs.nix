{ sources ? import ./nix/sources.nix
, config ? { }
, system ? builtins.currentSystem
,
}:
let
  nixpkgs = sources.nixpkgs;
  rust_overlay = import (sources.rust_overlay);

  overlays = [
    (self: super: {
      solana-source = self.callPackage (import ./solana-source.nix) { };
      solana-platform-tools = self.callPackage (import ./solana-platform-tools.nix) { };
      solana-rust = self.callPackage (import ./solana-rust.nix) { };
      solana-cli = self.callPackage (import ./solana-cli.nix) { };
      anchor-cli = self.callPackage (import ./anchor-cli.nix) { };
    }
    )
    rust_overlay
  ];
in
import nixpkgs { inherit config system overlays; }
