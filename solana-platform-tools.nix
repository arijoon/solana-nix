({ stdenv
 , autoPatchelfHook
 , criterion
 , fetchzip
 , lib
 , libclang
 , openssl
 , python38
 , solana-source
 , udev
 , xz
 , zlib
 , system ? builtins.currentSystem
 }:
let
  version = "v1.37";
  sha256 = "sha256-llKrtYIxM8YvIiJZauYdVIV4XISS7Jk4EZ/H4bCbfN4=";
in
stdenv.mkDerivation rec {
  pname = "solana-platform-tools";
  inherit version;

  src =
    let
      # The system string is inverted
      # TODO add darwin equivalent here
      systemMapping = {
        x86_64-linux = "linux-x86_64";
      };
    in
    fetchzip {
      url = "https://github.com/solana-labs/platform-tools/releases/download/${version}/platform-tools-${systemMapping."${system}"}.tar.bz2";
      inherit sha256;
      stripRoot = false;
    };

  doCheck = false;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    # Auto patching
    zlib
    stdenv.cc.cc
    openssl
    libclang.lib
    xz
    python38
  ] ++ lib.optionals stdenv.isLinux [ udev ];

  installPhase = ''
    platformtools=$out/bin/sdk/sbf/dependencies/platform-tools
    mkdir -p $platformtools
    cp -r $src/llvm $platformtools;
    cp -r $src/rust $platformtools
    chmod 0755 -R $out;
    touch $platformtools-${version}.md

    # Criterion is also needed
    criterion=$out/bin/sdk/sbf/dependencies/criterion
    mkdir $criterion
    ln -s ${criterion.dev}/include $criterion/include
    ln -s ${criterion}/lib $criterion/lib
    ln -s ${criterion}/share $criterion/share
    touch $criterion-v${criterion.version}.md

    cp -ar ${solana-source.src}/sdk/sbf/* $out/bin/sdk/sbf/
  '';


  meta = with lib; {
    description = "Solana SDK";
    homepage = "https://solana.com";
    platforms = platforms.linux;
  };
})
