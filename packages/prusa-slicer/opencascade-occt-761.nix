{ pkgs }:

# PrusaSlicer pins OpenCASCADE to 7.6.1: newer versions (up to and including
# 7.9.3, the one in nixpkgs) contain a bug that triangulates chamfers
# incorrectly (SPE-2257 in the PrusaSlicer issue tracker, still unfixed in
# 7.9.3). See deps/+OCCT/OCCT.cmake in the PrusaSlicer tree.
pkgs.opencascade-occt.overrideAttrs (old: {
  version = "7.6.1";
  src = pkgs.fetchFromGitHub {
    owner = "Open-Cascade-SAS";
    repo = "OCCT";
    rev = "V7_6_1";
    hash = "sha256-C02P3D363UwF0NM6R4D4c6yE5ZZxCcu5CpUaoTOxh7E=";
  };
  # The package's version-gated freetype backport patch is fetched from a
  # commit that no longer exists on the GitHub mirror (404), so drop it for
  # 7.6.1; if OCCT 7.6.1 hits the freetype issue on Linux we patch it here.
  patches = [ ];
})
