# https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/blockchains/solana/default.nix
({ stdenv
 , makeRustPlatform
 , rust-bin
 , fetchFromGitHub
 , lib
 , libgcc
 , darwin
 , clang
 , udev
 , protobuf
 , libcxx
 , rocksdb_8_11
 , snappy
 , pkg-config
 , makeWrapper
 , solana-platform-tools
 , solana-source
 , openssl
 , nix-update-script
   # Taken from https://github.com/solana-labs/solana/blob/master/scripts/cargo-install-all.sh#L84
 , solanaPkgs ? [
     "agave-install"
     "agave-install-init"
     "agave-ledger-tool"
     "agave-validator"
     "agave-watchtower"
     "cargo-build-sbf"
     "cargo-test-sbf"
     "rbpf-cli"
     "solana"
     "solana-bench-tps"
     "solana-faucet"
     "solana-gossip"
     "solana-keygen"
     "solana-log-analyzer"
     "solana-net-shaper"
     "solana-dos"
     "solana-stake-accounts"
     "solana-test-validator"
     "solana-tokens"
     "solana-genesis"
   ]
 }:
let
  version = solana-source.version;

  # nixpkgs 24.11 defaults to Rust v1.82.0, but Agave uses Rust v1.84.1
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.stable."1.84.1".default;
    rustc = rust-bin.stable."1.84.1".default;
  };

  inherit (darwin.apple_sdk_11_0) Libsystem;
  inherit (darwin.apple_sdk_11_0.frameworks) System IOKit AppKit Security;
in
rustPlatform.buildRustPackage rec {
  pname = "solana-cli";
  inherit version;

  src = solana-source.src;

  cargoLock = {
    lockFile = "${src.outPath}/Cargo.lock";
    outputHashes = {
      "crossbeam-epoch-0.9.5" = "sha256-Jf0RarsgJiXiZ+ddy0vp4jQ59J9m0k3sgXhWhCdhgws=";
    };
  };

  strictDeps = true;
  cargoBuildFlags = builtins.map (n: "--bin=${n}") solanaPkgs;

  # Even tho the tests work, a shit ton of them try to connect to a local RPC
  # or access internet in other ways, eventually failing due to Nix sandbox.
  # Maybe we could restrict the check to the tests that don't require an RPC,
  # but judging by the quantity of tests, that seems like a lengthty work and
  # I'm not in the mood ((ΦωΦ))
  doCheck = false;

  nativeBuildInputs = [ protobuf pkg-config ];
  buildInputs = [ openssl rustPlatform.bindgenHook makeWrapper ]
    ++ lib.optionals stdenv.isLinux [ udev ]
    ++ lib.optionals stdenv.isDarwin [
    libcxx
    IOKit
    Security
    AppKit
    System
    Libsystem
  ];
# wrapProgram $out/bin/tailscaled --prefix PATH : ${pkgs.lib.makeBinPath

  postInstall = ''
    mkdir -p $out/bin/platform-tools-sdk/sbf
    cp -a ./platform-tools-sdk/sbf/* $out/bin/platform-tools-sdk/sbf/

    rust=${solana-platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
    sbfsdkdir=${solana-platform-tools}/bin/platform-tools-sdk/sbf
    wrapProgram $out/bin/cargo-build-sbf \
      --prefix PATH : "$rust" \
      --set SBF_SDK_PATH "$sbfsdkdir" \
      --add-flags --no-rustup-override \
      --add-flags --skip-tools-install
  '';

  # Used by build.rs in the rocksdb-sys crate. If we don't set these, it would
  # try to build RocksDB from source.
  ROCKSDB_LIB_DIR = "${rocksdb_8_11}/lib";
  ROCKSDB_INCLUDE_DIR = "${rocksdb_8_11}/include";

  # Require this on darwin otherwise the compiler starts rambling about missing
  # cmath functions
  CPPFLAGS = lib.optionals stdenv.isDarwin "-isystem ${lib.getDev libcxx}/include/c++/v1";
  LDFLAGS = lib.optionals stdenv.isDarwin "-L${lib.getLib libcxx}/lib";

  # If set, always finds OpenSSL in the system, even if the vendored feature is enabled.
  OPENSSL_NO_VENDOR = 1;

  meta = with lib; {
    description = "Web-Scale Blockchain for fast, secure, scalable, decentralized apps and marketplaces. ";
    homepage = "https://solana.com";
    license = licenses.asl20;
    maintainers = with maintainers; [ netfox happysalada ];
    platforms = platforms.unix;
  };

  passthru.updateScript = nix-update-script { };
})
