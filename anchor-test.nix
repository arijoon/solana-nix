{
  stdenv,
  anchor-cli,
  runCommand,
}:
let
  src = runCommand "anchor-test-src" 
    {
      nativeBuildInputs = [ anchor-cli ];
    }
    ''
    mkdir -p $out
    cd $out
    anchor init example -j --no-install --no-git --test-template rust
    mv example/.* example/* .
    rm -rf example
    '';
in
stdenv.mkDerivation {
  pname = "anchor-test";
  inherit src;
  version = "1.0.0";

  doCheck = false;

  nativeBuildInputs = [ anchor-cli ];

  buildPhase = ''
    anchor build
    anchor test
  '';
  installPhase = ''
    echo ok > $out
  '';

  meta = {
    description = "Anchor build testing";
  };
}
