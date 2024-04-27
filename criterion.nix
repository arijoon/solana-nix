{ lib
, fetchFromGitHub
, cmake
, pkg-config
, criterion
}:
criterion.overrideAttrs rec {
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "Snaipe";
    repo = "Criterion";
    rev = "v${version}";
    sha256 = "sha256-F2HVlVdZxWRLlcxhu+9n09mhtAS+PbUF8mOSoiPyKng=";
    fetchSubmodules = true;
  };

  # Remove attrs for v2.4
  # https://github.com/NixOS/nixpkgs/commit/bff379e9ed908e737009038c24d548ba17e81ee2
  nativeBuildInputs = [ cmake pkg-config ];
  checkTarget = "criterion_tests test";
  cmakeFlags = [ "-DCTESTS=ON" ];
  # Disable this phase
  postPatch = "";
}
