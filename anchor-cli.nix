{
  stdenv,
  darwin,
  fetchFromGitHub,
  lib,
  pkg-config,
  protobuf,
  makeWrapper,
  solana-platform-tools,
  rust-bin,
  udev,
  crane,
}: let
  # Anchor does not declare a rust-toolchain, so we do it here -- the code
  # mentions Rust 1.85.0 at https://github.com/coral-xyz/anchor/blob/c509618412e004415c7b090e469a9e4d5177f642/docs/content/docs/installation.mdx?plain=1#L31
  craneLib =
    crane.overrideToolchain
    rust-bin.stable."1.85.0".default;

  pname = "anchor-cli";
  version = "0.31.0";

  src = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    rev = "v${version}";
    hash = "sha256-CaBVdp7RPVmzzEiVazjpDLJxEkIgy1BHCwdH2mYLbGM=";
  };

  commonArgs = {
    inherit pname version src;

    # ensure `buildDepsOnly` builds the proper files
    # otherwise in the final derivation we'd be using the unpatched `anchor_cli` crate
    dummySrc = src;
    patches = [./anchor-cli.patch];

    strictDeps = true;
    doCheck = false;

    nativeBuildInputs = [protobuf pkg-config makeWrapper];
    buildInputs =
      []
      ++ lib.optionals stdenv.isLinux [udev]
      ++ lib.optional stdenv.isDarwin
      [darwin.apple_sdk.frameworks.CoreFoundation];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
  craneLib.buildPackage (commonArgs
    // {
      inherit cargoArtifacts;

      # Ensure anchor has access to Solana's cargo and rust binaries
      postInstall = ''
        rust=${solana-platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
        wrapProgram $out/bin/anchor \
          --prefix PATH : "$rust"
      '';

      cargoExtraArgs = "-p ${pname}";

      meta = {
        description = "Anchor cli";
      };
    })
