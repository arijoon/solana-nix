{ lib, fetchFromGitHub, cmake, pkg-config, criterion }:
criterion.overrideAttrs rec {
  version = "2.3.3";

  src = fetchFromGitHub {
    owner = "Snaipe";
    repo = "Criterion";
    rev = "v${version}";
    sha256 = "sha256-F2HVlVdZxWRLlcxhu+9n09mhtAS+PbUF8mOSoiPyKng=";
    fetchSubmodules = true;
  };

  # Remove attrs for v2.4.1
  # https://github.com/NixOS/nixpkgs/commit/bff379e9ed908e737009038c24d548ba17e81ee2
  nativeBuildInputs = [ cmake pkg-config ];
  checkTarget = "criterion_tests test";
  cmakeFlags = [ "-DCTESTS=ON" ];
  # Disable this phase
  postPatch = "";
  # Remove attrs for v2.4.2
  # https://github.com/NixOS/nixpkgs/commit/558c5c6559730420356ee6703c0c351b2f97d3fb
  # Disable this phase
  prePatch = "";
}
