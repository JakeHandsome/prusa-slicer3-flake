{ pkgs }:

# facebook/yoga 3.1.0, the version pinned by PrusaSlicer 3.0 (deps/+yoga).
# The patch comes from the PrusaSlicer tree: it disables the test targets and
# comments out -Werror and -fno-rtti in the project defaults so the library
# builds as a plain static `yogacore` with the expected CMake target.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "yoga";
  version = "3.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "facebook";
    repo = "yoga";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Y/BHMAfMUBY2Z5VV6rZkBGMs8II+r6MWXM6oV+nxtaQ=";
  };

  patches = [ ./yoga.patch ];

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  doCheck = false;

  meta = {
    description = "Cross-platform, retargetable C++ auto layout library";
    homepage = "https://github.com/facebook/yoga";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.all;
  };
})
