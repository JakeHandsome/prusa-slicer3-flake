{ pkgs }:

# libassert 2.2.1, the version pinned by PrusaSlicer 3.0 (deps/+libassert).
#
# Built with LIBASSERT_USE_EXTERNAL_CPPTRACE=ON so it links against the
# system cpptrace instead of FetchContent-ing its own (Prusa's dependency
# build does the same). magic_enum and enchantum stay at their defaults
# (off), which keeps the build self-contained.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "libassert";
  version = "2.2.1";

  src = pkgs.fetchFromGitHub {
    owner = "jeremy-rifkin";
    repo = "libassert";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ognudQ3NgpYxiDEucbIRWYQPs0XLRUQwg1eMxJm+aPs=";
  };

  buildInputs = [ pkgs.cpptrace ];

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
  ];

  cmakeFlags = [
    "-DLIBASSERT_USE_EXTERNAL_CPPTRACE=ON"
    "-DBUILD_TESTING=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  doCheck = false;

  meta = {
    description = "Modern C++ assertions with source context and stack traces";
    homepage = "https://github.com/jeremy-rifkin/libassert";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.all;
  };
})
