({ stdenv
 , autoPatchelfHook
 , criterion
 , fetchzip
 , lib
 , libclang
 , libedit
 , python310
 , solana-source
 , udev
 , xz
 , zlib
 , system ? builtins.currentSystem
 }:
let
  version = "v1.43";
  sha256 = "GhMnfjKNJXpVqT1CZE0Zyp4+NXJG41sUxwHye9DGPt0=";
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
      url = "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-${systemMapping."${system}"}.tar.bz2";
      inherit sha256;
      stripRoot = false;
    };

  doCheck = false;

  nativeBuildInputs = [ autoPatchelfHook ];

  buildInputs = [
    # Auto patching
    libedit
    zlib
    stdenv.cc.cc
    libclang.lib
    xz
    python310
  ] ++ lib.optionals stdenv.isLinux [ udev ];

  installPhase = ''
    platformtools=$out/bin/sdk/sbf/dependencies/platform-tools
    mkdir -p $platformtools
    cp -r $src/llvm $platformtools
    cp -r $src/rust $platformtools
    chmod 0755 -R $out
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

  # A bit ugly, but liblldb.so uses libedit.so.2 and nix provides libedit.so
  postFixup = ''
    patchelf --replace-needed libedit.so.2 libedit.so $out/bin/sdk/sbf/dependencies/platform-tools/llvm/lib/liblldb.so.18.1.7-rust-dev
  '';

  meta = with lib; {
    description = "Solana Platform Tools";
    homepage = "https://solana.com";
    platforms = platforms.linux;
  };
})
