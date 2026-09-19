{ pkgs }:

# wxWidgets 3.3 built with CMake, which installs the CMake package config
# (wxWidgetsConfig.cmake with the wxWidgets::wxWidgets and wx::wx* targets)
# that PrusaSlicer 3.0 requires via `find_package(wxWidgets 3.3 CONFIG)`.
#
# nixpkgs' wxwidgets_3_3 builds the same sources with autotools and does not
# install a CMake config, so it cannot be used for PrusaSlicer 3.0.
#
# The build options mirror deps/+wxWidgets/wxWidgets.cmake in the PrusaSlicer
# tree (the flags PrusaSlicer's own dependency build passes).
let
  inherit (pkgs) lib;
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "wxwidgets";
  version = "3.3.3.1";

  src = pkgs.fetchFromGitHub {
    owner = "wxWidgets";
    repo = "wxWidgets";
    tag = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-gB+mEk8rHpB4z1m8RWJSV+upKzLt7pZtlviS2g03EHY=";
  };

  nativeBuildInputs = [
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
  ];

  buildInputs = [
    pkgs.gtk3
    pkgs.libGL
    pkgs.libGLU
    pkgs.libjpeg_turbo
    pkgs.libpng
    pkgs.zlib
    pkgs.expat
    pkgs.libsm
    pkgs.libxinerama
    pkgs.libxtst
    pkgs.libxxf86vm
    pkgs.libnotify
    pkgs.libxkbcommon
    pkgs.xorgproto
    # GTK3 is built with Wayland; wx generates the wayland protocol headers it
    # needs with wayland-scanner (a separate derivation from the wayland
    # library in nixpkgs).
    pkgs.wayland
    pkgs.wayland-scanner
    # wxUSE_NANOSVG=sys -> NanoSVG::nanosvg targets (see nanosvg-fltk.nix)
    (import ./nanosvg-fltk.nix { inherit pkgs; })
    # wxUSE_WEBVIEW=ON -> webview/webview_webkit
    pkgs.webkitgtk_4_1
  ];

  cmakeFlags = [
    # wx's functions.cmake includes GNUInstallDirs, which makes
    # CMAKE_INSTALL_BINDIR & co. absolute ($out/bin & co). wx's install then
    # builds paths like ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR} for the
    # wxrc/wx-config symlinks, doubling the prefix and creating broken
    # symlinks. Relative install dirs keep both usages correct.
    "-DCMAKE_INSTALL_BINDIR=bin"
    "-DCMAKE_INSTALL_LIBDIR=lib"
    "-DCMAKE_INSTALL_INCLUDEDIR=include"
    "-DBUILD_SHARED_LIBS=ON"
    "-DwxBUILD_TOOLKIT=gtk3"
    "-DwxBUILD_PRECOMP=OFF"
    # Don't build the per-locale .mo files; PrusaSlicer defines
    # WXINTL_NO_GETTEXT_MACRO and never uses wx's gettext integration.
    "-DwxBUILD_LOCALES=OFF"
    "-DwxUSE_MEDIACTRL=OFF"
    "-DwxUSE_DETECT_SM=OFF"
    "-DwxUSE_UNICODE_UTF8=ON"
    "-DwxUSE_OPENGL=ON"
    "-DwxUSE_LIBPNG=sys"
    "-DwxUSE_ZLIB=sys"
    "-DwxUSE_NANOSVG=sys"
    "-DwxUSE_REGEX=OFF"
    "-DwxUSE_LIBXPM=builtin"
    "-DwxUSE_LIBJPEG=sys"
    "-DwxUSE_LIBTIFF=OFF"
    "-DwxUSE_LIBWEBP=OFF"
    "-DwxUSE_EXPAT=sys"
    "-DwxUSE_LIBSDL=OFF"
    "-DwxUSE_STC=OFF"
    "-DwxUSE_XTEST=OFF"
    "-DwxUSE_GLCANVAS_EGL=OFF"
    "-DwxUSE_WEBREQUEST=OFF"
    "-DwxUSE_UNSAFE_WXSTRING_CONV=OFF"
    "-DwxUSE_EXCEPTIONS=OFF"
    "-DwxUSE_WEBVIEW=ON"
    "-DwxUSE_SECRETSTORE=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ];

  enableParallelBuilding = true;

  meta = {
    description = "Cross-Platform C++ GUI Library (CMake build, for PrusaSlicer)";
    homepage = "https://www.wxwidgets.org/";
    license = with pkgs.lib.licenses; [ lgpl2Plus wxWindowsException31 ];
    platforms = pkgs.lib.platforms.unix;
  };
})
