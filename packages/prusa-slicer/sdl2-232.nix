{ pkgs }:

# PrusaSlicer's bundled imgui build unconditionally runs find_package(SDL2 2)
# for its SDL2/OpenGL3 backend (even though PrusaSlicer only links the plain
# OpenGL3 backend). nixpkgs' SDL2 attribute is sdl2-compat (an SDL3 shim) and
# provides neither a CMake config nor a pkg-config file, so build real SDL2
# 2.32.x with CMake, the same version PrusaSlicer's own dependency build uses
# (see deps/+SDL/SDL.cmake in the PrusaSlicer tree).
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "SDL2";
  version = "2.32.4";

  # Same release as PrusaSlicer's dependency build (deps/+SDL/SDL.cmake);
  # the GitHub tarball instead of the release zip, which stdenv cannot
  # unpack.
  src = pkgs.fetchFromGitHub {
    owner = "libsdl-org";
    repo = "SDL";
    tag = "release-2.32.4";
    hash = "sha256-4yUJkttUAbDC/5IdcCFY5ZTIG1qsxEEOjTTuplXV/p4=";
  };

  nativeBuildInputs = [ pkgs.cmake pkgs.ninja pkgs.pkg-config ];

  buildInputs = [
    # X11 and Wayland video drivers; audio/hidapi/joystick stay off, the
    # imgui backend only needs the video + GL context parts of SDL2.
    pkgs.libx11
    pkgs.libxext
    pkgs.libxrandr
    pkgs.libxinerama
    pkgs.libxcursor
    pkgs.libxi
    pkgs.xorgproto
    pkgs.libxcb
    pkgs.wayland
    pkgs.libxkbcommon
  ];

  cmakeFlags = [
    # Relative install dirs; SDL2's sdl2.pc.in joins them onto
    # ${prefix}/${exec_prefix} and absolute values would double the store
    # prefix (nixpkgs#144170).
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_SHARED_LIBS=ON"
    "-DSDL2_SHARED=ON"
    "-DSDL2_X11=ON"
    "-DSDL2_WAYLAND=ON"
    "-DSDL2_AUDIO=OFF"
    "-DSDL2_HIDAPI=OFF"
    "-DSDL2_JOYSTICK=OFF"
    "-DSDL2_IBUS=OFF"
    "-DSDL2_LIBUDEV=OFF"
    "-DSDL2_TESTS=OFF"
    "-DSDL2_SAMPLES=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  meta = {
    description = "Simple DirectMedia Layer, a low-level multimedia API";
    homepage = "https://www.libsdl.org/";
    license = pkgs.lib.licenses.zlib;
    platforms = pkgs.lib.platforms.unix;
  };
})
