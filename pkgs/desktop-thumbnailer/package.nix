{ pkgs, ... }:

let
  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "desktop-thumbnailer";
    rev = "b831d03";
    sha256 = "sha256-Scza33/VPyu/JSL7dpCUMgpJjfrFY2RVToV2/WfQw2I=";
  };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "desktop-thumbnailer";
  version = "0.1.1";

  src = src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  postPatch = ''
    substituteInPlace desktop-thumbnailer.thumbnailer \
      --replace-fail "Exec=desktop-thumbnailer %i %o %s" "Exec=$out/bin/desktop-thumbnailer %i %o %s"
  '';

  buildPhase = ''
    cargo build --release
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    install -Dm755 target/release/desktop-thumbnailer $out/bin/

    mkdir -p $out/share/thumbnailers/
    cp desktop-thumbnailer.thumbnailer $out/share/thumbnailers/
    runHook postInstall
  '';

  meta = with pkgs.lib; {
    homepage = "https://github.com/sachesi/desktop-thumbnailer/";
    description = "Fast, lightweight .desktop thumbnailer";
    license = licenses.gpl3;
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
