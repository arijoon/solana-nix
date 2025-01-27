{ stdenv
, darwin
, fetchFromGitHub
, lib
, libgcc
, pkg-config
, protobuf
, makeRustPlatform
, makeWrapper
, solana-platform-tools
, rust-bin
, udev
}:
let
  # Anchor does not declare a rust-toolchain, so we have to do it here -- the
  # old dependency on the `time` crate doesn't support Rust versions >= 1.80.
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.stable."1.79.0".default;
    rustc = rust-bin.stable."1.79.0".default;
  };
in
rustPlatform.buildRustPackage rec {
  pname = "anchor-cli";
  version = "0.30.1";

  doCheck = false;

  nativeBuildInputs = [ protobuf pkg-config makeWrapper ];
  buildInputs = [ ]
    ++ lib.optionals stdenv.isLinux [ udev ]
    ++ lib.optional
    stdenv.isDarwin [
    darwin.apple_sdk.frameworks.CoreFoundation
  ];

  src = fetchFromGitHub {
    owner = "coral-xyz";
    repo = "anchor";
    rev = "v${version}";
    hash = "sha256-3fLYTJDVCJdi6o0Zd+hb9jcPDKm4M4NzpZ8EUVW/GVw=";
  };

  cargoLock = {
    lockFile = "${src.outPath}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  patches = [
    ./anchor-cli.patch
  ];

  buildAndTestSubdir = "cli";

  # Ensure anchor has access to Solana's cargo and rust binaries
  postInstall = ''
    rust=${solana-platform-tools}/bin/sdk/sbf/dependencies/platform-tools/rust/bin
    wrapProgram $out/bin/anchor \
      --prefix PATH : "$rust"
  '';

  meta = {
    description = "Anchor cli";
  };
}
