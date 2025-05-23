{ pkgs, ... }:

let
  src = pkgs.fetchgit {
    url = "ssh://git@github.com:sachesi/custom-icons.git";
    rev = "11dc70hin9xdgvi0v3qby2lrl1bpgig4mmf64hzc291q5gpsnfna";
    sha256 = "sha256-yjqr7ys4JME+JMbVSl58dwWaqfALjw3ifq0nGyE4rIU=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.1-2";
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
