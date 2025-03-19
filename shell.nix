let pkgs = import ./pkgs.nix { };
in pkgs.mkShell {
  buildInputs = with pkgs; [ anchor-cli solana-cli solana-rust yarn nodejs ];
}
