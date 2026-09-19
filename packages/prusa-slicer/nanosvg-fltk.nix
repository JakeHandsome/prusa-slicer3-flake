{ pkgs }:

# The CMake-based NanoSVG fork that PrusaSlicer 3.0 builds, which also exports
# the NanoSVG::nanosvg / NanoSVG::nanosvgrast CMake targets that wxWidgets 3.3
# consumes when built with wxUSE_NANOSVG=sys.
#
# nixpkgs' `nanosvg` package builds the original upstream source without a
# CMake config, so PrusaSlicer's `find_package(NanoSVG)` would not find it.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "nanosvg-fltk";
  version = "0-unstable-2022-12-22";

  src = pkgs.fetchFromGitHub {
    owner = "fltk";
    repo = "nanosvg";
    rev = "abcd277ea45e9098bed752cf9c6875b533c0892f";
    hash = "sha256-WNdAYu66ggpSYJ8Kt57yEA4mSTv+Rvzj9Rm1q765HpY=";
  };

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
  ];

  # PrusaSlicer builds this as a static library.
  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = {
    description = "NanoSVG (fltk fork) with CMake targets, used by PrusaSlicer and wxWidgets";
    homepage = "https://github.com/fltk/nanosvg";
    license = pkgs.lib.licenses.zlib;
    platforms = pkgs.lib.platforms.all;
  };
})
