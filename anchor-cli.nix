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
  writeShellScriptBin,
  version ? "0.31.1",
}:
let
  pname = "anchor-cli";

  # Anchor IDL generation makes use of rust-nightly
  # therefore we want to expose it to the environment to be used
  # Due to https://github.com/solana-foundation/anchor/pull/3663
  # latest nightly is always preferred when possible, since breakage may occur
  # due to differing dependency versions as well
  versionsDeps = {
    "0.31.1" = {
      hash = "sha256-c+UybdZCFL40TNvxn0PHR1ch7VPhhJFDSIScetRpS3o=";
      rust = rust-bin.stable."1.85.0".default;
      rust-nightly = rust-bin.nightly.latest.default;
      platform-tools = solana-platform-tools.override { version = "1.45"; };
      patches = [ ./patches/anchor-cli/0.31.1.patch ];
    };
    "0.31.0" = {
      hash = "sha256-CaBVdp7RPVmzzEiVazjpDLJxEkIgy1BHCwdH2mYLbGM=";
      rust = rust-bin.stable."1.85.0".default;
      rust-nightly = rust-bin.nightly.latest.default;
      platform-tools = solana-platform-tools.override { version = "1.45"; };
      patches = [ ./patches/anchor-cli/0.31.0.patch ];
    };
    "0.30.1" = {
      hash = "sha256-3fLYTJDVCJdi6o0Zd+hb9jcPDKm4M4NzpZ8EUVW/GVw=";
      rust = rust-bin.stable."1.78.0".default;
      # anchor-syn v0.30.1 still uses the old API
      rust-nightly = rust-bin.nightly."2025-04-15".default;
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

  # We create a small cargo shim to dispatch to a compatible nightly version when necessary
  cargoShim = writeShellScriptBin "cargo" ''
    # Check that required env variables are set
    if [[ -z "$_NIX_SUPPORT_STABLE_TOOLCHAIN" || -z "$_NIX_SUPPORT_NIGHTLY_TOOLCHAIN" ]]; then
      echo "Error: Both _NIX_SUPPORT_STABLE_TOOLCHAIN and _NIX_SUPPORT_NIGHTLY_TOOLCHAIN environment variables must be set." >&2
      exit 1
    fi

    if [[ "$1" == "+nightly" ]]; then
      # Shift off +nightly and pass through all remaining args
      shift
      export PATH="$_NIX_SUPPORT_NIGHTLY_TOOLCHAIN":$PATH
      exec cargo "$@"
    else
      export PATH="$_NIX_SUPPORT_STABLE_TOOLCHAIN":$PATH
      exec cargo "$@"
    fi
  '';
in
craneLib.buildPackage (
  commonArgs
  // {
    inherit cargoArtifacts;

    # Ensure anchor has access to Solana's rust binaries and our cargo shim with nightly
    postInstall = ''
      rust=${versionDeps.platform-tools}/bin/platform-tools-sdk/sbf/dependencies/platform-tools/rust/bin
      wrapProgram $out/bin/anchor \
        --prefix PATH : "${cargoShim}/bin" \
        --set _NIX_SUPPORT_STABLE_TOOLCHAIN "$rust" \
        --set _NIX_SUPPORT_NIGHTLY_TOOLCHAIN "${versionDeps.rust-nightly}/bin"
    '';

    cargoExtraArgs = "-p ${pname}";

    meta = {
      mainProgram = "anchor";
      description = "Anchor cli";
    };

    passthru = {
      otherVersions = builtins.attrNames versionsDeps;
      rustNightly = versionDeps.rust-nightly._version;
    };
  }
)
