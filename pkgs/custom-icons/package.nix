{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "custom-icons";
    rev = "bef2f3ab03b91e84f65e414fb4a5f2941abb02e8";
    sha256 = "sha256-HnOerW9QLmDhRG580tx2AvKSeOGXx2+OxqQPjW1i1P0=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-6";
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
