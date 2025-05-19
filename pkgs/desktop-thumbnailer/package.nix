{ pkgs, rustToolchain, ... }:

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
  version = "0.1.0";

  src = src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  RUSTC = "${rustToolchain}/bin/rustc";
  CARGO = "${rustToolchain}/bin/cargo";

  nativeBuildInputs = [ rustToolchain ];

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
    description = "Fast, lightweight and minimalistic Wayland terminal emulator";
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
