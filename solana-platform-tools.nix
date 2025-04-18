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
  version = "v1.45";
  sha256 = "QGm7mOd3UnssYhPt8RSSRiS5LiddkXuDtWuakpak0Y0=";
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
    platformtools=$out/bin/platform-tools-sdk/sbf/dependencies/platform-tools
    mkdir -p $platformtools
    cp -r $src/llvm $platformtools
    cp -r $src/rust $platformtools
    chmod 0755 -R $out
    touch $platformtools-${version}.md

    # Criterion is also needed
    criterion=$out/bin/platform-tools-sdk/sbf/dependencies/criterion
    mkdir $criterion
    ln -s ${criterion.dev}/include $criterion/include
    ln -s ${criterion}/lib $criterion/lib
    ln -s ${criterion}/share $criterion/share
    touch $criterion-v${criterion.version}.md

    cp -ar ${solana-source.src}/platform-tools-sdk/sbf/* $out/bin/platform-tools-sdk/sbf/
  '';

  # A bit ugly, but liblldb.so uses libedit.so.2 and nix provides libedit.so
  postFixup = ''
    patchelf --replace-needed libedit.so.2 libedit.so $out/bin/platform-tools-sdk/sbf/dependencies/platform-tools/llvm/lib/liblldb.so.18.1.7-rust-dev
  '';

  meta = with lib; {
    description = "Solana Platform Tools";
    homepage = "https://solana.com";
    platforms = platforms.linux;
  };
})
