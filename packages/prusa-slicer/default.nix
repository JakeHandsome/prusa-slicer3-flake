{
  pkgs,
}:

let
  inherit (pkgs) lib;

  opencascade-occt-761 = import ./opencascade-occt-761.nix { inherit pkgs; };

  # Packages PrusaSlicer 3.0 looks up with find_package that nixpkgs does not
  # provide in the expected form. Each file documents why.
  wxwidgets3-cmake = import ./wxwidgets3-cmake.nix { inherit pkgs; };
  tracy-client = import ./tracy-client.nix { inherit pkgs; };
  nanosvg-fltk = import ./nanosvg-fltk.nix { inherit pkgs; };
  yoga = import ./yoga.nix { inherit pkgs; };
  libassert = import ./libassert.nix { inherit pkgs; };
  prusa-fdm-mixer = import ./prusa-fdm-mixer.nix { inherit pkgs; };
  sdl2 = import ./sdl2-232.nix { inherit pkgs; };
  nlohmann-json = import ./nlohmann-json.nix { inherit pkgs; };
in
pkgs.clangStdenv.mkDerivation (finalAttrs: {
  pname = "prusa-slicer";
  version = "3.0.0-alpha11";

  src = pkgs.fetchFromGitHub {
    owner = "prusa3d";
    repo = "PrusaSlicer";
    rev = "version_${finalAttrs.version}";
    hash = "sha256-U+5CYJ6mykZA37uqPKeDyKcQfTmgG1BCRV8dVhLWTHs=";
  };

  strictDeps = true;

  # On first start the app copies its preset bundle from the (read-only)
  # install location into ~/.config/PrusaSlicer3-dev/presets/local/. Upstream
  # uses boost::filesystem::copy, which preserves source modes: from a Nix
  # store path (dirs 0555, files 0444) the copy dies partway through with a
  # permission error, and the leftover partial bundle then shadows the intact
  # app bundle on every following start. The patch copies with writable modes
  # and cleans up on failure instead of aborting.
  patches = [ ./writable-local-bundle-copy.patch ];

  # GCC runs out of memory on the slic3r-core build; the nixpkgs 2.9.x
  # package builds with clang for the same reason.
  nativeBuildInputs = [
    pkgs.binutils
    pkgs.cmake
    pkgs.ninja
    pkgs.pkg-config
    pkgs.wrapGAppsHook3
  ]
  ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs.udevCheckHook
    pkgs.systemd
  ];

  buildInputs = [
    # GUI toolkit stack (wxWidgets is the CMake build; see wxwidgets3-cmake.nix)
    wxwidgets3-cmake
    pkgs.gtk3
    pkgs.glib
    pkgs.glib-networking
    # wxWidgets' CMake config exports these as bare -l names (not in its
    # INTERFACE_LINK_DIRECTORIES), so they must be on the consumer's linker
    # search path to resolve the final link.
    pkgs.libnotify
    pkgs.wayland
    pkgs.fontconfig
    # The installed executable carries a direct NEEDED entry for
    # libxkbcommon.so.0 (pulled in via the gtk/gdk/wx stack), and the
    # executable's RUNPATH is composed only from our direct buildInputs, so
    # it must be declared here even though it is a transitive dep of gtk+3.
    pkgs.libxkbcommon
    pkgs.webkitgtk_4_1
    pkgs.hicolor-icon-theme
    pkgs.libx11
    pkgs.expat
    pkgs.libpng
    pkgs.libjpeg_turbo
    pkgs.glew
    pkgs.glfw
    pkgs.libGL
    pkgs.libGLU
    pkgs.gmp
    pkgs.mpfr

    # Core dependencies
    pkgs.boost186
    pkgs.cereal
    pkgs.cli11
    pkgs.cpptrace
    pkgs.curl
    pkgs.dbus
    pkgs.eigen
    pkgs.fmt
    pkgs.hidapi
    pkgs.lua
    pkgs.openssl
    pkgs.nlopt
    pkgs.z3
    # std::optional-aware headers; see nlohmann-json.nix for why nixpkgs'
    # stock build is not usable here
    nlohmann-json
    pkgs.pugixml
    pkgs.tl-expected
    pkgs.range-v3
    pkgs.magic-enum
    pkgs.spdlog
    pkgs.sol2
    pkgs.yaml-cpp
    pkgs.libdeflate
    pkgs.heatshrink
    pkgs.libbgcode

    # Geometry / 3D
    opencascade-occt-761
    pkgs.openvdb
    # nixpkgs builds openvdb with BLOSC, ZLIB and delayed loading enabled;
    # PrusaSlicer's FindOpenVDB.cmake then requires these packages itself.
    pkgs.c-blosc
    pkgs.zlib
    pkgs.qhull
    pkgs.cgal_5
    pkgs.onetbb

    # 3.0-only dependencies (see the individual package files)
    tracy-client
    nanosvg-fltk
    yoga
    libassert
    prusa-fdm-mixer
    # Real SDL2 (CMake config) for the bundled imgui's SDL2 backend
    sdl2
    # Interpreter for the generated prusa-gcodeviewer launcher script (its
    # store path is in the script's shebang, so it must be in the closure).
    pkgs.dash
  ];

  env.NLOPT = "${pkgs.nlopt}";

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    # nixpkgs builds boost with dynamic log libraries. Note: passing this on
    # the command line replaces (not extends) the CXXFLAGS environment, so a
    # user's NIX_CXXFLAGS does not reach this package's CMake configure.
    "-DCMAKE_CXX_FLAGS=-DBOOST_LOG_DYN_LINK"
    # Some sub-projects (wx-free bundled code, OCCT headers) predate CMake 4
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.10"
    # Shared libraries; OCCTWrapper is a MODULE loaded via dlopen
    "-DSLIC3R_STATIC=0"
    # Install resources under $out/share
    "-DSLIC3R_FHS=1"
    # Use the system yaml-cpp; the other backends (libfyaml, ryml) are not
    # available in nixpkgs in the CMake-config form PrusaSlicer expects
    "-DSLIC3R_YAML=yaml-cpp"
    # Upstream's test targets are not wired into this build (see doCheck).
    "-DSLIC3R_BUILD_TESTS=OFF"
  ];

  prePatch = ''
    # Disable nlohmann implicit conversions in every translation unit, matching
    # PrusaSlicer's own dependency build (JSON_ImplicitConversions=OFF).
    # Combined with the patched nlohmann headers this is what makes
    # get<std::optional<...>>() available in the config loader. Passed as a
    # CMake compile definition rather than a CXXFLAGS entry because nix
    # word-splits cmakeFlags and would turn the second token into a no-op
    # CMake variable.
    sed -i '/^project(PrusaSlicer)/a add_compile_definitions(JSON_USE_IMPLICIT_CONVERSIONS=0)' CMakeLists.txt
    grep -q 'add_compile_definitions(JSON_USE_IMPLICIT_CONVERSIONS=0)' CMakeLists.txt \
      || fail "failed to add JSON_USE_IMPLICIT_CONVERSIONS after project(PrusaSlicer)"

    # expat now ships a CMake config providing the expat::expat target, so the
    # in-tree FindEXPAT.cmake (which predates it) is a nuisance and is removed,
    # the same way the 2.9.x nixpkgs package handled it.
    rm cmake/modules/FindEXPAT.cmake

    # The in-tree FindNLopt.cmake references nlopt_cxx, the library name used
    # by nlopt < 2.0. nixpkgs ships nlopt >= 2.0, which only builds libnlopt.
    substituteInPlace cmake/modules/FindNLopt.cmake \
      --replace-fail "nlopt_cxx" "nlopt"

    # Several sources use std::memcpy/std::memset without including <cstring>;
    # GCC pulls it in transitively, clang does not.
    for f in \
        src/slic3r-biz-crypto/src/Slic3r/Biz/Crypto/Types.cpp \
        src/slic3r-render/src/Slic3r/App/Render/ImageCodec.cpp \
        src/slic3r-shared/src/Slic3r/App/Plater/LayerHeightGizmoHelper.cpp \
        src/slic3r-shared/src/Slic3r/Biz/Format/3mf.cpp \
        src/slic3r-shared/src/Slic3r/Biz/Network/HttpCurl.cpp; do
        sed -i '1i #include <cstring>' "$f"
    done
    for f in \
        src/slic3r-biz-crypto/src/Slic3r/Biz/Crypto/Types.cpp \
        src/slic3r-render/src/Slic3r/App/Render/ImageCodec.cpp \
        src/slic3r-shared/src/Slic3r/App/Plater/LayerHeightGizmoHelper.cpp \
        src/slic3r-shared/src/Slic3r/Biz/Format/3mf.cpp \
        src/slic3r-shared/src/Slic3r/Biz/Network/HttpCurl.cpp; do
        head -n1 "$f" | grep -q '#include <cstring>' \
          || fail "failed to add '#include <cstring>' to $f"
    done

    # clang treats the single-element braced-init-list attach({&c}) as
    # ambiguous between the StateColor& and std::vector<StateColor const*>&
    # overloads (the 2+-element call sites resolve fine). Make the intended
    # vector explicit.
    sed -i 's/state_handler\.attach({&text_color});/state_handler.attach(std::vector<StateColor const *>{\&text_color});/' \
        src/slic3r-shared-wx/src/Slic3r/App/WX/Widgets/Button.cpp
    grep -q 'state_handler.attach(std::vector<StateColor const \*>{&text_color});' \
      src/slic3r-shared-wx/src/Slic3r/App/WX/Widgets/Button.cpp \
      || fail "failed to rewrite the ambiguous attach({&text_color}) call"
  '';

  # Upstream's CTest wiring is left unverified; keep the test targets off.
  doCheck = false;

  postInstall = ''
    # The single installed binary is a launcher that hosts both the GUI and
    # the G-code viewer (selected via --gcodeviewer).
    mv $out/bin/slic3r-app-launcher $out/bin/prusa-slicer

    # G-code viewer entry point. The 3.0 launcher picks the viewer mode from
    # the --gcodeviewer argument; the app also re-spawns the
    # prusa-gcodeviewer binary from its own directory for new instances.
    # The shebang names dash's store path: /bin/sh is a runtime requirement,
    # and the script is exec'd by the gapps C wrapper at every launch.
    {
      echo "#!${pkgs.dash}/bin/dash"
      cat <<'EOF'
    exec "$(dirname "$0")/prusa-slicer" --gcodeviewer "$@"
    EOF
    } > $out/bin/prusa-gcodeviewer
    chmod 0755 $out/bin/prusa-gcodeviewer

    # OCCTWrapper.so is a MODULE the app dlopens from its own directory, not
    # an executable. wrapGAppsHook would otherwise wrap it (it wraps every
    # executable in $out/bin), replacing the shared library with a C wrapper
    # and breaking STEP loading. dlopen does not require the exec bit, so drop
    # it to keep the hook from touching the library.
    chmod a-x $out/bin/OCCTWrapper.so

    # shared-mime-info glob entries for .3mf. Glob entries only extend the
    # MIME database's filename patterns; they register no application as a
    # handler (that would need a .desktop entry with MimeType=). Upstream
    # keeps a PrusaGcodeviewer.desktop source with MimeType=text/x.gcode, but
    # its CMake installs no .desktop file at all.
    mkdir -p $out/share/mime/packages
    cat > $out/share/mime/packages/prusa-gcode-viewer.xml <<'EOF'
    <?xml version="1.0"?>
    <mime-info xmlns="http://www.freedesktop.org/specs/shared-mime-info/1.0">
      <glob type="application/vnd.ms-3mfdocument" pattern="*.3mf"/>
      <glob type="application/x-3mf" pattern="*.3mf"/>
    </mime-info>
    EOF

    # Application menu entry. Upstream CMake only configures the Flatpak-flavored
    # com.prusa3d.PrusaSlicer.desktop.in and never installs a .desktop file, so
    # without this the app is unreachable from the menu. The plain
    # src/platform/unix/PrusaSlicer.desktop matches what nixpkgs ships for 2.9.x
    # (Exec=prusa-slicer, StartupWMClass=prusa-slicer). The icon ships inside the
    # resource bundle, outside the icon theme search path, so copy it into
    # hicolor for the desktop entry's Icon=PrusaSlicer to resolve.
    install -Dm644 $src/src/platform/unix/PrusaSlicer.desktop $out/share/applications/PrusaSlicer.desktop
    install -Dm644 $out/share/PrusaSlicer/icons/PrusaSlicer.svg $out/share/icons/hicolor/scalable/apps/PrusaSlicer.svg
  '';

  meta = {
    description = "3D printer slicer supporting Prusa, MakerBot, RepRap and other printers";
    longDescription = ''
      PrusaSlicer is a full-featured 3D printing preparation software. It takes
      STL, OBJ, 3MF, and other 3D model formats and slices them into G-code
      for FDM and other 3D printers.
    '';
    homepage = "https://www.prusa3d.com";
    license = pkgs.lib.licenses.agpl3Plus;
    # Only x86_64-linux is provided by the flake and verified to build.
    platforms = [ "x86_64-linux" ];
    maintainers = [ ];
    mainProgram = "prusa-slicer";
  };
})
