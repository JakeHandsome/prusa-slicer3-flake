# prusa-slicer-flake

This flake provides prusa slicer 3.0 alpha versions for early testing.  
Created with AI (Qwen3.8-27B)

## Install instructions

### Add the flake input

In your configuration's `flake.nix`:

```nix
inputs.prusa-slicer3.url = "github:JakeHandsome/prusa-slicer3-flake";
```

The flake currently provides packages for `x86_64-linux` only.

### Add the package with NixOS

Add it to your system packages and destructure the input in your outputs:

```nix
environment.systemPackages = [ prusa-slicer3.packages.${system}.prusa-slicer ];
```

Then rebuild with `nixos-rebuild switch`.

### Add the package with home-manager

Add it to your home packages and destructure the input in your outputs:

```nix
home.packages = [ prusa-slicer3.packages.${system}.prusa-slicer ];
```

Then rebuild with `home-manager switch`.

### Build locally

For testing, build the default package from the flake directory:

```sh
nix build
```

This creates a `result` symlink to the built store path. The flake's `flake.lock` pins nixpkgs, so the build uses the same revision regardless of your system's. You can then run the binary directly:

```sh
./result/bin/prusa-slicer
```

To explicitly name the package instead of relying on the default:

```sh
nix build .#prusa-slicer
```
