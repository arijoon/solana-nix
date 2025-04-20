({
  stdenv,
  autoPatchelfHook,
  criterion,
  fetchzip,
  lib,
  libclang,
  libedit,
  python310,
  solana-source,
  udev,
  xz,
  zlib,
  system ? builtins.currentSystem,
}: let
  version = "v1.45";
  # The system string is inverted, and each bundle has a different hash
  systemMappings = {
    x86_64-linux = {
      system = "linux-x86_64";
      hash = "sha256-QGm7mOd3UnssYhPt8RSSRiS5LiddkXuDtWuakpak0Y0=";
    };
    aarch64-linux = {
      system = "linux-aarch64";
      hash = "sha256-UzOekFBdjtHJzzytmkQETd6Mrb+cdAsbZBA0kzc75Ws=";
    };
    x86_64-darwin = {
      sytem = "osx-x86_64";
      hash = "sha256-EE7nVJ+8a/snx4ea7U+zexU/vTMX16WoU5Kbv5t2vN8=";
    };
    aarch64-darwin = {
      system = "osx-aarch64";
      hash = "sha256-aJjYD4vhsLcBMAC8hXrecrMvyzbkas9VNF9nnNxtbiE=";
    };
    x86_64-windows = {
      system = "windows-x86_64";
      hash = "sha256-7D7NN2tClnQ/UAwKUZEZqNVQxcKWguU3Fs1pgsC5CIk=";
    };
  };
  systemMapping = systemMappings."${system}";
in
  stdenv.mkDerivation rec {
    pname = "solana-platform-tools";
    inherit version;

    src = fetchzip {
      url = "https://github.com/anza-xyz/platform-tools/releases/download/${version}/platform-tools-${systemMapping.system}.tar.bz2";
      hash = systemMapping.hash;
      stripRoot = false;
    };

    doCheck = false;

    # https://github.com/NixOS/nixpkgs/issues/380196#issuecomment-2646189651
    dontCheckForBrokenSymlinks = true;

    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];

    buildInputs =
      [
        # Auto patching
        libedit
        zlib
        stdenv.cc.cc
        libclang.lib
        xz
        python310
      ]
      ++ lib.optionals stdenv.isLinux [udev];

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
      patchelf --replace-needed libedit.so.2 libedit.so $out/bin/platform-tools-sdk/sbf/dependencies/platform-tools/llvm/lib/liblldb.so.18.1.7-rust-dev
    '';

    # We need to preserve metadata in .rlib, which might get stripped on macOS. See https://github.com/NixOS/nixpkgs/issues/218712
    stripExclude = ["*.rlib"];

    meta = with lib; {
      description = "Solana Platform Tools";
      homepage = "https://solana.com";
      platforms = platforms.aarch64 ++ platforms.unix;
    };
  })
