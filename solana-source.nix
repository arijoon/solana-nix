{ stdenv
, fetchFromGitHub
}:
let
  version = "2.1.11";
  sha256 = "Wtc5+PkuZdicreImj9n0qqk6ZVwBZSlJytO1WTMoiMw=";
in
{
  inherit version;
  src = fetchFromGitHub {
    owner = "anza-xyz";
    repo = "agave";
    rev = "v${version}";
    fetchSubmodules = true;
    inherit sha256;
  };
}

