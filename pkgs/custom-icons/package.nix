{ pkgs, ... }:

let
  src = pkgs.fetchgit {
    url = "ssh://git@github.com:sachesi/custom-icons.git";
    rev = "1c0587cdc0aec619cd6a0836b9373604c717b815";
    sha256 = "sha256-lMoMaa2O/VUwPdG/xfQCEiwCcWO005s8IHa8dNviMmk=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.1-8";
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
