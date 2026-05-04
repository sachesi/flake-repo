{ pkgs, ... }:

let
  inherit (pkgs)
    lib
    buildFHSEnv
    writeShellScript
    fetchurl
    runCommand
    imagemagick
    makeDesktopItem
    symlinkJoin
    ;

  # Runtime dependencies for the Tauri/WebKit-based launcher
  runtimeDeps = with pkgs; [
    glib
    gtk3
    webkitgtk_4_1
    gdk-pixbuf
    libsoup_3
    cairo
    pango
    harfbuzz
    atk
    openssl
    zlib
    icu
    libGL
  ];

  hytale-launcher-fhs = buildFHSEnv {
    name = "hytale-launcher";

    targetPkgs =
      pkgs:
      runtimeDeps
      ++ (with pkgs; [
        # Additional runtime deps
        libx11
        libxcursor
        libxrandr
        libxi
        libxcb
        libxkbcommon
        mesa
        vulkan-loader
        alsa-lib
        pulseaudio
        dbus
        gsettings-desktop-schemas
        glib
        hicolor-icon-theme
        adwaita-icon-theme
        icu
        libGL
        # Tools for downloading and patching
        curl
        unzip
        patchelf
      ]);

    profile = ''
      export GDK_BACKEND=x11
      export WEBKIT_DISABLE_COMPOSITING_MODE=1
      export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS"
    '';

    runScript = writeShellScript "hytale-launcher-wrapper" ''
      set -e

      LAUNCHER_DIR="$HOME/.local/share/hytale-launcher"
      LAUNCHER_BIN="$LAUNCHER_DIR/hytale-launcher"
      DOWNLOAD_URL="https://launcher.hytale.com/builds/release/linux/amd64/hytale-launcher-latest.zip"

      # Create launcher directory
      mkdir -p "$LAUNCHER_DIR"

      # Download and set up launcher if it doesn't exist
      if [ ! -f "$LAUNCHER_BIN" ]; then
        echo "Downloading Hytale Launcher..."
        TEMP_DIR=$(mktemp -d)
        trap "rm -rf $TEMP_DIR" EXIT

        curl -L -o "$TEMP_DIR/launcher.zip" "$DOWNLOAD_URL"
        unzip -o "$TEMP_DIR/launcher.zip" -d "$TEMP_DIR"
        mv "$TEMP_DIR/hytale-launcher" "$LAUNCHER_BIN"
        chmod +x "$LAUNCHER_BIN"

        echo "Hytale Launcher installed successfully!"
      fi

      # Run from mutable location (allows self-updates)
      cd "$LAUNCHER_DIR"
      exec "$LAUNCHER_BIN" "$@"
    '';

    meta = with lib; {
      description = "Hytale Game Launcher";
      homepage = "https://hytale.com";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "hytale-launcher";
      maintainers = [
        {
          name = "sachesi x";
          email = "sachesi.bb.passp@proton.me";
          github = "sachesi";
        }
      ];
    };
  };

  # Desktop entry file
  desktopItem = makeDesktopItem {
    name = "hytale-launcher";
    desktopName = "Hytale Launcher";
    comment = "Official Hytale Game Launcher";
    exec = "hytale-launcher";
    icon = "hytale-launcher";
    terminal = false;
    type = "Application";
    categories = [ "Game" ];
    keywords = [
      "hytale"
      "game"
      "launcher"
    ];
  };

  # Fetch the Hytale icon
  # Fix for Issue #3: Use favicon.png as favicon.ico is now 404
  hytaleIcon = fetchurl {
    url = "https://cdn2.steamgriddb.com/icon/f9189ab8a3d3920fa3cee4bc216d09a6/32/256x256.png";
    hash = "sha256-7y/z8cEQl7B6owm84qE1tn+b0VFm3h5G6b3WDsPIWag=";
  };

  # Convert icon to png for better compatibility
  hytaleIconPng =
    runCommand "hytale-launcher-icon"
      {
        nativeBuildInputs = [ imagemagick ];
      }
      ''
        mkdir -p $out
        # Extract the largest icon from the source and convert to png
        convert ${hytaleIcon} -thumbnail 256x256 -alpha on -background none -flatten $out/hytale-launcher.png
      '';

  meta = hytale-launcher-fhs.meta;
in
symlinkJoin {
  name = "hytale-launcher";
  paths = [
    hytale-launcher-fhs
    desktopItem
  ];
  postBuild = ''
    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp ${hytaleIconPng}/hytale-launcher.png $out/share/icons/hicolor/256x256/apps/hytale-launcher.png

    mkdir -p $out/share/pixmaps
    cp ${hytaleIconPng}/hytale-launcher.png $out/share/pixmaps/hytale-launcher.png
  '';
  inherit meta;
}
