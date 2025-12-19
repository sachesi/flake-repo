{ pkgs, ... }:

let
  python = pkgs.python3.withPackages (
    ps: with ps; [
      pygobject3
    ]
  );

  appName = "libre-menu-editor";
in

pkgs.stdenv.mkDerivation rec {
  pname = appName;
  version = "1.10.1";

  src = pkgs.fetchgit {
    url = "https://codeberg.org/libre-menu-editor/libre-menu-editor.git";
    rev = "a2fb9a18e39ce38cf93af5cb32758c591e715c9c";
    sha256 = "sha256-B/f6VQGm4q+LNFEW0tJP8vVeCj3MUCQxWyZsKpa3GK4=";
  };

  dontBuild = true;

  nativeBuildInputs = [
    pkgs.makeWrapper
    pkgs.wrapGAppsHook4
  ];

  buildInputs = [
    python
    pkgs.gtk4
    pkgs.libadwaita
    pkgs.gobject-introspection
    pkgs.xdg-utils
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share
    mkdir -p $out/share/${appName}

    # Copy the Python application files
    cp -r ${appName}/* $out/share/${appName}/

    # Copy binary files
    cp export/bin/${appName} $out/bin/
    chmod +x $out/bin/${appName}

    # Copy share files
    cp -r export/share/* $out/share/

    # Create a wrapper script
    makeWrapper ${python.interpreter} $out/bin/${appName} \
      --add-flags "$out/share/${appName}/main.py" \
      --set PYTHONPATH "$out/share/${appName}:${python}/${python.sitePackages}" \
      --prefix GI_TYPELIB_PATH : "${pkgs.gtk4}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.libadwaita}/lib/girepository-1.0" \
      --prefix GI_TYPELIB_PATH : "${pkgs.glib}/lib/girepository-1.0" \
      --prefix PATH : "${pkgs.xdg-utils}/bin"
  '';

  meta = with pkgs.lib; {
    description = "GNOME menu editor written in Python using GTK4 and libadwaita";
    homepage = "https://codeberg.org/libre-menu-editor/libre-menu-editor";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
