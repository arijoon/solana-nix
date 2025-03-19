{ stdenv, fetchFromGitHub }:
let
  version = "2.2.3";
  sha256 = "sha256-nRCamrwzoPX0cAEcP6p0t0t9Q41RjM6okupOPkJH5lQ=";
in {
  inherit version;
  src = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "agave";
    rev = "v${version}";
    fetchSubmodules = true;
    inherit sha256;
  };
}

