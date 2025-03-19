({
    stdenv,
    autoPatchelfHook,
    lib,
    solana-cli,
    solana-platform-tools,
  }:
    stdenv.mkDerivation {
      pname = "solana-rust";
      version = solana-cli.version;

      phases = ["installPhase"];
      nativeBuildInputs = [autoPatchelfHook];

      buildInputs = [solana-platform-tools];

      installPhase = ''
        mkdir -p $out/bin
        rust=${solana-platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
        ln -s $rust/cargo $out/bin/cargo
        ln -s $rust/rustc $out/bin/rustc
      '';

      meta = with lib; {
        description = "Solana SDK";
        homepage = "https://solana.com";
        platforms = platforms.unix;
      };
    })
