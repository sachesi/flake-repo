{ pkgs, ... }:

let
  lib = pkgs.lib;
in
pkgs.rustPlatform.buildRustPackage rec {
  pname = "dethumb";
  version = "0.3.1";

  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "dethumb";
    rev = "v${version}";

    hash = "sha256-pVwTUQ+oLrp+fM3FeQgJyChL1UvoGQbj8N/PIHyfkko=";
  };

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  postPatch = ''
    substituteInPlace packaging/usr/share/thumbnailers/dethumb.thumbnailer \
      --replace-fail "TryExec=dethumb" "TryExec=$out/bin/dethumb" \
      --replace-fail "Exec=dethumb %i %o %s" "Exec=$out/bin/dethumb %i %o %s"
  '';

  postInstall = ''
    install -Dm644 \
      packaging/usr/share/thumbnailers/dethumb.thumbnailer \
      "$out/share/thumbnailers/dethumb.thumbnailer"
  '';

  meta = with lib; {
    homepage = "https://github.com/sachesi/dethumb";
    description = "Small Rust thumbnailer for Linux .desktop files and Windows .exe binaries";
    license = licenses.gpl3Only;
    mainProgram = "dethumb";
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
