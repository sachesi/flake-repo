{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "custom-icons";
    rev = "60a67dbae2f37c3cef7720e9f181391a902d795b";
    sha256 = "sha256-mZPs0CO9oL6MFgxvAzJ6oxcUJvlpXVJuJZ4shnhATbY=";
  };
in
pkgs.stdenv.mkDerivation {
  pname = "custom-icons";
  version = "0.2-5";
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
