{ pkgs, ... }:

let
  lib = pkgs.lib;

  src = fetchGit {
    url = "git@github.com:sachesi/custom-icons.git";
    ref = "main";
    rev = "59d0a45a5b3c18ac08116c8f0ed0d7fc4da375e3";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-12";

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
