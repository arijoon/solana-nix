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
  runCommand,
  version ? "0.31.1",
}:
let
  pname = "anchor-cli";

  versionsDeps = {
    "0.31.1" = {
      hash = "sha256-c+UybdZCFL40TNvxn0PHR1ch7VPhhJFDSIScetRpS3o=";
      # Unfortunately dependency on nightly compiler seems to be common
      # in rust projects
      rust-nightly = rust-bin.nightly."2025-04-21".minimal;
      rust = rust-bin.stable."1.85.0".default;
      platform-tools = solana-platform-tools.override { version = "1.45"; };
      patches = [ ./patches/anchor-cli/0.31.1.patch ];
    };
    "0.31.0" = {
      hash = "sha256-CaBVdp7RPVmzzEiVazjpDLJxEkIgy1BHCwdH2mYLbGM=";
      rust = rust-bin.stable."1.85.0".default;
      platform-tools = solana-platform-tools.override { version = "1.45"; };
      patches = [ ./patches/anchor-cli/0.31.0.patch ];
    };
    "0.30.1" = {
      hash = "sha256-3fLYTJDVCJdi6o0Zd+hb9jcPDKm4M4NzpZ8EUVW/GVw=";
      rust = rust-bin.stable."1.78.0".default;
      platform-tools = solana-platform-tools.override { version = "1.43"; };
      patches = [ ./patches/anchor-cli/0.30.1.patch ];
    };
  };
  versionDeps = versionsDeps.${version};

  craneLib = crane.overrideToolchain versionDeps.rust;

  originalSrc = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    rev = "v${version}";
    hash = versionDeps.hash;
  };

  src = stdenv.mkDerivation {
    name = "anchor-cli-patched";
    src = originalSrc;

    # Apply the patch
    phases = [
      "unpackPhase"
      "patchPhase"
      "installPhase"
    ];
    patches = versionDeps.patches;

    # Install the patched source as an output
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r ./* $out/
      runHook postInstall
    '';
  };

  commonArgs = {
    inherit pname version src;

    strictDeps = true;
    doCheck = false;

    nativeBuildInputs = [
      protobuf
      pkg-config
      makeWrapper
    ];
    buildInputs =
      [ ]
      ++ lib.optionals stdenv.isLinux [ udev ]
      ++ lib.optional stdenv.isDarwin [ darwin.apple_sdk.frameworks.CoreFoundation ];
  };

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    # Ensure anchor has access to Solana's cargo and rust binaries
    postInstall = let 
      # Due to th way anchor is calling cargo if its not wrapped
      # with its own toolchain, it'll access solana rust compiler instead
      # hence the nightly entry points must be wrapped with the nightly bins
      # to guarantee correct usage
      # In this case we've limited the nightly bin access to `cargo`
      cargo-nightly = runCommand "cargo-nightly" {
        nativeBuildInputs = [ makeWrapper ];
      } ''
        mkdir -p $out/bin

        ln -s ${versionDeps.rust-nightly}/bin/cargo $out/bin/cargo

        # Wrap cargo nightly so it uses the nightly toolchain only
        wrapProgram $out/bin/cargo \
          --prefix PATH : "${versionDeps.rust-nightly}/bin"
      ''
    ;
    in 
    ''
      rust=${versionDeps.platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
      wrapProgram $out/bin/anchor \
        --prefix PATH : "$rust" ${if versionDeps ? rust-nightly then "--set RUST_NIGHTLY_BIN \"${cargo-nightly}/bin\"" else ""}
    '';

    cargoExtraArgs = "-p ${pname}";

    meta = {
      mainProgram = "anchor";
      description = "Anchor cli";
    };

    passthru = {
      otherVersions = builtins.attrNames versionsDeps;
    };
  }
)
