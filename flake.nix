{
  description = "PrusaSlicer 3.0 alpha";

  # Pinned to the nixos-unstable revision the package was built and tested
  # against (2026-09-16). Bumping it may require re-resolving the patches in
  # packages/prusa-slicer (toolchain header behavior and nixpkgs package
  # versions shift between revisions).
  inputs.nixpkgs.url = "github:nixos/nixpkgs/b1b875982b17dabde9b4a37f3e229e74913e6db3";

  outputs =
    { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      prusa-slicer = import ./packages/prusa-slicer { inherit pkgs; };
    in
    {
      packages."x86_64-linux" = {
        prusa-slicer = prusa-slicer;
      };

      defaultPackage."x86_64-linux" = prusa-slicer;
    };
}
