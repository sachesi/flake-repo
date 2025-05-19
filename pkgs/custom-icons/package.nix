{ pkgs, ... }:

let
  src = pkgs.fetchgit {
    url = "ssh://git@github.com:sachesi/custom-icons.git";
    rev = "1q0pl0acfxs25yphd96hjh3cmbai0dfggr2z57dchn7c28srjzqs";
    sha256 = "sha256-Gn+ZNRLsWMjaKV/k91wDUa3KBpTQpAavL0J3xxSgF+A=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.1";
  src = src;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/hicolor/256x256/apps
    cp -r icons/hicolor/256x256/apps/* $out/share/icons/hicolor/256x256/apps/

    runHook postInstall
  '';

  meta = with pkgs.lib; {
    description = "Custom app icons for my apps";
    homepage = "https://github.com/sachesi/desktop-thumbnailer/";
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
