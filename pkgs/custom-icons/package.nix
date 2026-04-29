{ pkgs, ... }:

let
  lib = pkgs.lib;

  src = fetchGit {
    url = "git@github.com:sachesi/custom-icons.git";
    ref = "main";
    rev = "08d3b696c84a591e4f198152e5cd8f67ab383786";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-16";

  inherit src;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -d "$out/share/icons/hicolor/256x256/apps"
    cp -r icons/hicolor/256x256/apps/* "$out/share/icons/hicolor/256x256/apps/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Custom icons for my apps";
    homepage = "https://github.com/sachesi/custom-icons/";
    license = licenses.free;
    maintainers = [
      {
        name = "sachesi x";
        email = "sachesi.bb.passp@proton.me";
        github = "sachesi";
      }
    ];
    platforms = platforms.linux;
  };
}
