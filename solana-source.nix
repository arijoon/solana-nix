{ stdenv, fetchFromGitHub }:
let
  version = "2.3.7";
  sha256 = "sha256-PZtnPBQbQwr5Ezogzv5ujALTaMcFAIZhPhaBQWt1jp8=";
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
