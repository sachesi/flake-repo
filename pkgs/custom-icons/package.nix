{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "custom-icons";
    rev = "8f78bfbaaa3846bdf9565a0e274ff0a6299896fa";
    sha256 = "sha256-kBO0rz2TWM0+0Bkjmtfl2pBhURiQG+Ale0aCjbE3OXA=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-3";
  src = src;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp -r icons/hicolor/256x256/apps/* $out/share/icons/hicolor/256x256/apps/

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Custom icons for my apps";
    homepage = "https://github.com/sachesi/custom-icons/";
    license = pkgs.lib.licenses.free;
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
