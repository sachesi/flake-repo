{ pkgs, ... }:

let
  src = pkgs.fetchgit {
    url = "ssh://git@github.com:sachesi/custom-icons.git";
    rev = "98a0d77abd2543e92f3d691456815b3818970159";
    sha256 = "sha256-AxppghBK0jqtH4IekwZbwVRqvciO2KgSlXMBUq1MP/o=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.1-7";
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
