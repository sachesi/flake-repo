{ pkgs, ... }:

let
  lib = pkgs.lib;

  appName = "libre-menu-editor";

  python = pkgs.python3.withPackages (
    ps: with ps; [
      pygobject3
    ]
  );
in
pkgs.stdenv.mkDerivation rec {
  pname = appName;
  version = "1.10.2";

  src = pkgs.fetchFromGitea {
    domain = "codeberg.org";
    owner = "libre-menu-editor";
    repo = "libre-menu-editor";
    rev = "v${version}";

    hash = "sha256-qY7td2qZIkSTKFkSZkarjxGN3MJ0wg1IQkXoXFwFOJ4=";
  };

  dontBuild = true;
  dontWrapGApps = true;

  nativeBuildInputs = with pkgs; [
    makeWrapper
    wrapGAppsHook4
  ];

  buildInputs = with pkgs; [
    python
    gtk4
    libadwaita
    glib
    gdk-pixbuf
    gobject-introspection
    xdg-utils
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    mkdir -p "$out/share/${appName}"

    cp -r ${appName}/* "$out/share/${appName}/"
    cp -r export/share/* "$out/share/"

    makeWrapper ${python.interpreter} "$out/bin/${appName}" \
      --add-flags "$out/share/${appName}/main.py" \
      --set PYTHONPATH "$out/share/${appName}:${python}/${python.sitePackages}" \
      --prefix PATH : "${lib.makeBinPath [ pkgs.xdg-utils ]}" \
      --prefix GI_TYPELIB_PATH : "${
        lib.makeSearchPath "lib/girepository-1.0" [
          pkgs.gtk4
          pkgs.libadwaita
          pkgs.glib
          pkgs.gdk-pixbuf
        ]
      }" \
      "''${gappsWrapperArgs[@]}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "GNOME menu editor written in Python using GTK4 and libadwaita";
    homepage = "https://codeberg.org/libre-menu-editor/libre-menu-editor";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    mainProgram = appName;
  };
}
