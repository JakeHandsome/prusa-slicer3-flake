{ pkgs }:

# nixpkgs' nlohmann_json 3.12.0 installs the stock headers, in which the
# std::optional from_json overload is guarded by
#   #ifndef JSON_USE_IMPLICIT_CONVERSIONS
# i.e. it only exists when implicit conversions are *disabled* via an
# undefined macro. PrusaSlicer builds with implicit conversions off
# (JSON_ImplicitConversions=OFF, -DJSON_USE_IMPLICIT_CONVERSIONS=0 on the
# consumer side) and calls ordered_json::get<std::optional<int>>() /
# get<std::vector<std::optional<int>>>() in its config loader, which needs
# that overload. PrusaSlicer's own dependency build therefore patches the
# guard (deps/+json/json.patch). We rebuild the header-only library with the
# same patch so the installed headers match what the code expects.
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "nlohmann_json";
  version = "3.12.0";

  src = pkgs.fetchFromGitHub {
    owner = "nlohmann";
    repo = "json";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cECvDOLxgX7Q9R3IE86Hj9JJUxraDQvhoyPDF03B2CY=";
  };

  patches = [
    # Same char8_t detection fix nixpkgs applies (upstream PR #4736),
    # vendored from the upstream commit patch so the build does not fetch
    # from a non-flake URL.
    ./json-char8.patch
    # From PrusaSlicer's own dependency build: make the std::optional
    # from_json available when JSON_USE_IMPLICIT_CONVERSIONS is defined as 0.
    ./json.patch
  ];

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
  ];

  cmakeFlags = [
    # Relative install dirs; nlohmann_json.pc joins them onto ${prefix} and
    # absolute values would double the store prefix (nixpkgs#144170).
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DJSON_BuildTests=OFF"
    # Split headers, the layout nixpkgs installs and the code's
    # #include <nlohmann/...> paths expect.
    "-DJSON_MultipleHeaders=ON"
  ];

  # Header-only: nothing to check without the (git-dependent) test suite.
  doCheck = false;

  meta = {
    description = "JSON for Modern C++ (with PrusaSlicer's std::optional guard patch)";
    homepage = "https://json.nlohmann.me";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.all;
  };
})
