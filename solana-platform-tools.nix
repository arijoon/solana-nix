{
  stdenv,
  autoPatchelfHook,
  criterion,
  fetchzip,
  lib,
  libclang,
  libedit,
  openssl,
  python310,
  solana-source,
  udev,
  xz,
  zlib,
  system ? builtins.currentSystem,
  version ? "1.48",
}:
let
  systemMapping = {
    x86_64-linux = "linux-x86_64";
    aarch64-linux = "linux-aarch64";
    x86_64-darwin = "osx-x86_64";
    aarch64-darwin = "osx-aarch64";
    x86_64-windows = "windows-x86_64";
  };

  versionMapping = {
    "1.48" = {
      x86_64-linux = "sha256-vHeOPs7B7WptUJ/mVvyt7ue+MqfqAsbwAHM+xlN/tgQ=";
      aarch64-linux = "sha256-i3I9pwa+DyMJINFr+IucwytzEHdiRZU6r7xWHzppuR4=";
      x86_64-darwin = "sha256-bXV4S8JeM4RJ7D9u+ruwtNFJ9aq01cFw80sprxB+Xng=";
      aarch64-darwin = "sha256-ViXRoGlfn0aduNaZgsiXTcSIZO560DmFF5+kh3kYNIA=";
      x86_64-windows = "sha256-hEVs9TPLX2YY2SBwt8qE8b700yznC71NHszz/zXdpZQ=";
    };
    "1.45" = {
      x86_64-linux = "sha256-QGm7mOd3UnssYhPt8RSSRiS5LiddkXuDtWuakpak0Y0=";
      aarch64-linux = "sha256-UzOekFBdjtHJzzytmkQETd6Mrb+cdAsbZBA0kzc75Ws=";
      x86_64-darwin = "sha256-EE7nVJ+8a/snx4ea7U+zexU/vTMX16WoU5Kbv5t2vN8=";
      aarch64-darwin = "sha256-aJjYD4vhsLcBMAC8hXrecrMvyzbkas9VNF9nnNxtbiE=";
      x86_64-windows = "sha256-7D7NN2tClnQ/UAwKUZEZqNVQxcKWguU3Fs1pgsC5CIk=";
    };
    "1.43" = {
      aarch64-darwin = "sha256-rt9LEz6Dp7bkrqtP9sgkvxY8tG3hqewD3vBXmJ5KMGk=";
      x86_64-linux = "sha256-GhMnfjKNJXpVqT1CZE0Zyp4+NXJG41sUxwHye9DGPt0=";
      aarch64-linux = "sha256-7YSPEaVErLIpDEqHj3oRTBzcP9L8BBzz6wWxZIet9jk=";
      x86_64-darwin = "sha256-qIx8NDM2SIaBOBkxd4jp1oo/kl2lBzEgXz4yqjRioJg=";
      x86_64-windows = "sha256-XX593OJMboZYmvdLSwgygZ/CZVxSUMig82+a8cCF/Dw=";
    };
  };
  # The system string is inverted, and each bundle has a different hash
  releaseSystem = systemMapping."${system}";
  releaseHash = versionMapping."${version}"."${system}";
in
stdenv.mkDerivation rec {
  pname = "solana-platform-tools";
  inherit version;

  src = fetchzip {
    url = "https://github.com/anza-xyz/platform-tools/releases/download/v${version}/platform-tools-${releaseSystem}.tar.bz2";
    hash = releaseHash;
    stripRoot = false;
  };

  doCheck = false;

  # https://github.com/NixOS/nixpkgs/issues/380196#issuecomment-2646189651
  dontCheckForBrokenSymlinks = true;

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  buildInputs = [
    # Auto patching
    libedit
    zlib
    stdenv.cc.cc
    libclang.lib
    xz
    python310
  ] ++ lib.optionals stdenv.isLinux [ openssl udev ];

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
  postFixup = lib.optionals stdenv.isLinux ''
    patchelf --replace-needed libedit.so.2 libedit.so $out/bin/platform-tools-sdk/sbf/dependencies/platform-tools/llvm/lib/liblldb.so.19.1.7-rust-dev
  '';

  # We need to preserve metadata in .rlib, which might get stripped on macOS. See https://github.com/NixOS/nixpkgs/issues/218712
  stripExclude = [ "*.rlib" ];

  meta = with lib; {
    description = "Solana Platform Tools";
    homepage = "https://solana.com";
    platforms = platforms.aarch64 ++ platforms.unix;
  };

  passthru = {
    otherVersions = builtins.attrNames versionMapping;
  };
}
