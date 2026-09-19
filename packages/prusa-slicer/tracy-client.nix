{ pkgs }:

# The Tracy profiler *client* library, i.e. the `Tracy::TracyClient` CMake
# target that PrusaSlicer 3.0 links against (with TRACY_ENABLE=ON).
#
# nixpkgs' `tracy` package only builds the standalone server/profiling
# application, not the client library.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "tracy-client";
  version = "0.13.1";

  src = pkgs.fetchFromGitHub {
    owner = "wolfpld";
    repo = "tracy";
    tag = "v${finalAttrs.version}";
    hash = "sha256-D4aQ5kSfWH9qEUaithR0W/E5pN5on0n9YoBHeMggMSE=";
  };

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
  ];

  cmakeFlags = [
    "-DTRACY_ENABLE=ON"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  doCheck = false;

  meta = {
    description = "Tracy profiler client library";
    homepage = "https://github.com/wolfpld/tracy";
    license = pkgs.lib.licenses.bsd3;
    platforms = pkgs.lib.platforms.all;
  };
})
