{
  pkgs,
  ...
}:

let
  lib = pkgs.lib;
  python = pkgs.python3;
in
python.pkgs.buildPythonApplication rec {
  pname = "protonupd";
  version = "3.0.3";
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "sachesi";
    repo = "protonupd";
    rev = "v${version}";

    # First build will fail and print the real hash.
    # Replace lib.fakeHash with the "got:" hash from Nix.
    hash = "sha256-hrr2y+kZIedDDYb0k/RLG6OHVFJV5rMowhyFlQu4aoA=";
  };

  build-system = with python.pkgs; [
    setuptools
    wheel
  ];

  # No external Python deps currently; protonupd uses Python stdlib.
  dependencies = [ ];

  # No test suite in repo currently.
  doCheck = false;

  pythonImportsCheck = [
    "protonupd"
  ];

  postInstall = ''
    install -Dm644 assets/usr/share/bash-completion/completions/protonupd \
      "$out/share/bash-completion/completions/protonupd"

    install -Dm644 assets/usr/share/zsh/site-functions/_protonupd \
      "$out/share/zsh/site-functions/_protonupd"

    install -Dm644 assets/usr/share/fish/vendor_completions.d/protonupd.fish \
      "$out/share/fish/vendor_completions.d/protonupd.fish"
  '';

  meta = with lib; {
    description = "CLI tool to download and install Proton builds into one central store";
    homepage = "https://github.com/sachesi/protonupd";
    license = licenses.gpl3Plus;
    mainProgram = "protonupd";
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
