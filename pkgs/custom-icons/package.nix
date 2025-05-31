{ pkgs, ... }:

let
  src = pkgs.fetchgit {
    url = "ssh://git@github.com:sachesi/custom-icons.git";
    rev = "02iz2436ffvsjnp7masl8g9f5mkjply83260k5xa92n8wl4bcwb7";
    sha256 = "sha256-Z3G2COXIiqR6mcCIgTy9ctbi0kNUq3qulXo7ZwYRPwo=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.1-4";
  src = src;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp -r icons/hicolor/256x256/apps/* $out/share/icons/hicolor/256x256/apps/

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Custom app icons for my apps";
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
