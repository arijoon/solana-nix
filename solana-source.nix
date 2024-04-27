{ stdenv
, fetchFromGitHub
}:
let
  version = "1.17.28";
  sha256 = "y79zsUfYsX377ofsFSg9a2il99uJsA+qdCu3J+EU5nQ=";
in
{
  inherit version;
  src = fetchFromGitHub {
    owner = "solana-labs";
    repo = "solana";
    rev = "v${version}";
    fetchSubmodules = true;
    inherit sha256;
  };
}

