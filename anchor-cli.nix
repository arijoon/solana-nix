{ stdenv
, darwin
, fetchFromGitHub
, lib
, libgcc
, pkg-config
, protobuf
, rustPlatform
, makeWrapper
, solana-platform-tools
, udev
}:
rustPlatform.buildRustPackage rec {
  pname = "anchor-cli";
  version = "0.29.0";

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
    hash = "sha256-mftge1idALb4vwyF8wGo6qLmrnvCBK3l+Iw7txCyhDc=";
  };

  cargoLock = {
    lockFile = "${src.outPath}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };

  buildAndTestSubdir = "cli";

  patches = [
    # Set default architecture to sbf instead of bpf
    ./anchor-cli.patch
  ];

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
