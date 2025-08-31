# https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/applications/blockchains/solana/default.nix
{
  stdenv,
  lib,
  darwin,
  udev,
  protobuf,
  libcxx,
  rocksdb,
  pkg-config,
  makeWrapper,
  solana-platform-tools,
  solana-source,
  openssl,
  nix-update-script,
  makeRustPlatform,
  rust-bin,
  crane,
  # Taken from https://github.com/solana-labs/solana/blob/master/scripts/cargo-install-all.sh#L84
  solanaPkgs ? [
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
  ],
}:
let
  version = solana-source.version;
  src = solana-source.src;

  # Use Rust 1.86.0 as required by Agave
  rust = rust-bin.stable."1.86.0".default;
  rustPlatform = makeRustPlatform {
    cargo = rust;
    rustc = rust;
  };
  craneLib = crane.overrideToolchain rust;

  inherit (darwin.apple_sdk_11_0) Libsystem;
  inherit (darwin.apple_sdk_11_0.frameworks)
    System
    IOKit
    AppKit
    Security
    ;

  commonArgs = {
    pname = "solana-cli";
    inherit src version;

    strictDeps = true;
    cargoExtraArgs = lib.concatMapStringsSep " " (n: "--bin=${n}") solanaPkgs;

    # Even tho the tests work, a shit ton of them try to connect to a local RPC
    # or access internet in other ways, eventually failing due to Nix sandbox.
    # Maybe we could restrict the check to the tests that don't require an RPC,
    # but judging by the quantity of tests, that seems like a lengthty work and
    # I'm not in the mood ((ΦωΦ))
    doCheck = false;

    nativeBuildInputs = [
      protobuf
      pkg-config
    ];
    buildInputs =
      [
        openssl
        rustPlatform.bindgenHook
        makeWrapper
      ]
      ++ lib.optionals stdenv.isLinux [ udev ]
      ++ lib.optionals stdenv.isDarwin [
        libcxx
        IOKit
        Security
        AppKit
        System
        Libsystem
      ];

    # https://crane.dev/faq/rebuilds-bindgen.html?highlight=bindgen#i-see-the-bindgen-crate-constantly-rebuilding
    NIX_OUTPATH_USED_AS_RANDOM_SEED = "aaaaaaaaaa";

    # Used by build.rs in the rocksdb-sys crate
    ROCKSDB_LIB_DIR = "${rocksdb}/lib";
    ROCKSDB_INCLUDE_DIR = "${rocksdb}/include";

    # For darwin systems
    CPPFLAGS = lib.optionals stdenv.isDarwin "-isystem ${lib.getDev libcxx}/include/c++/v1";
    LDFLAGS = lib.optionals stdenv.isDarwin "-L${lib.getLib libcxx}/lib";

    # If set, always finds OpenSSL in the system, even if the vendored feature is enabled.
    OPENSSL_NO_VENDOR = 1;
  };

  cargoArtifacts = craneLib.buildDepsOnly (
    commonArgs
    // {
      # inherit cargoVendorDir;
      # specify dummySrc manually to avoid errors when parsing the manifests for target-less crates
      # such as client-test. The sources rarely change in this context so it shouldn't matter much
      # TODO: use proper (custom) dummySrc
      dummySrc = src;
    }
  );
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    postInstall = ''
      mkdir -p $out/bin/platform-tools-sdk/sbf
      cp -a ./platform-tools-sdk/sbf/* $out/bin/platform-tools-sdk/sbf/

      rust=${solana-platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
      sbfsdkdir=${solana-platform-tools}/bin/platform-tools-sdk/sbf
      wrapProgram $out/bin/cargo-build-sbf \
        --prefix PATH : "$rust" \
        --set SBF_SDK_PATH "$sbfsdkdir" \
        --append-flags --no-rustup-override \
        --append-flags --skip-tools-install
    '';

    meta = with lib; {
      mainProgram = "solana";
      description = "Web-Scale Blockchain for fast, secure, scalable, decentralized apps and marketplaces. ";
      homepage = "https://solana.com";
      license = licenses.asl20;
      maintainers = with maintainers; [
        netfox
        happysalada
      ];
      platforms = platforms.unix;
    };

    passthru.updateScript = nix-update-script { };
  }
)
