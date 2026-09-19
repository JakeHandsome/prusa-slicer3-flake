{ pkgs }:

# prusa-fdm-mixer, the FDM filament-mixing solver library that PrusaSlicer 3.0
# links as prusa_fdm_mixer::prusa_fdm_mixer.
#
# PrusaSlicer builds it with its own CMake files (deps/+prusa_fdm_mixer in the
# PrusaSlicer tree), since the upstream project's CMake does not install a
# package config. Those two files are copied verbatim into this directory.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "prusa-fdm-mixer";
  version = "1.0.0";

  # Pinned to the commit referenced by PrusaSlicer 3.0's deps/+prusa_fdm_mixer.
  src = pkgs.fetchFromGitHub {
    owner = "prusa3d";
    repo = "prusa-fdm-mixer";
    rev = "09d372aeccb4f7b9a0efbe59d99d70dba196814a";
    hash = "sha256-3t4K+T8uRaAyhbTQTwM+sEmbYCAMrsh4jaGtTLKxMGw=";
  };

  # The CMake project lives in the cpp/ subdirectory of the repository;
  # src.name is the unpacked directory inside the build tree.
  sourceRoot = "${finalAttrs.src.name}/cpp";

  # PrusaSlicer's CMake files for this project (the upstream ones do not
  # export an install-tree package config).
  preConfigure = ''
    cp ${./prusa-fdm-mixer-CMakeLists.txt} CMakeLists.txt
    cp ${./prusa-fdm-mixer-Config.cmake.in} Config.cmake.in
  '';

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  doCheck = false;

  meta = {
    description = "FDM multi-material filament mixing solver, used by PrusaSlicer";
    homepage = "https://github.com/prusa3d/prusa-fdm-mixer";
    license = pkgs.lib.licenses.agpl3Only;
    platforms = pkgs.lib.platforms.all;
  };
})
