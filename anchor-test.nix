{
  stdenv,
  anchor-cli,
  solana-cli,
  solana-rust,
  runCommand,
  nodejs,
  yarn,
  cacert
}:
let
  src =
    runCommand "anchor-test-src"
      {
        nativeBuildInputs = [
          anchor-cli
          nodejs
          yarn
        ];
      }
      ''
        mkdir -p $out
        cd $out
        export HOME=$(mktemp -d)
        RUST_LOG=trace anchor init example --javascript --no-install --no-git --package-manager yarn
        mv example/.* example/* .
        rm -rf example
      '';
in
stdenv.mkDerivation {
  # Disable sandboxing
  # this is for CI live test check and we want to make sure
  # anchor init and build work when ran by a user
  __noChroot = true;
  pname = "anchor-test";
  inherit src;
  version = "1.0.0";

  doCheck = false;

  nativeBuildInputs = [
    anchor-cli
    solana-cli
    nodejs
    yarn
    solana-rust
    cacert 
  ];

  buildPhase = ''
    export HOME=$(mktemp -d)
    yarn install
    solana-keygen new --no-bip39-passphrase
    anchor build
    anchor test
  '';

  # Write an output so its cached
  installPhase = ''
    echo ok > $out
  '';

  meta = {
    description = "Anchor build testing of a new project initialised";
  };
}
