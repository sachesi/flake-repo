{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "custom-icons";
    rev = "85056548399bdb18cb743d8fcd111ee9f0acd721";
    sha256 = "sha256-1T7MBo/MTag4h3VXfxK+mehqhbM+yWR8aVuF9+SOQLc=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-8";
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
