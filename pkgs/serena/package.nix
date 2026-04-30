{
  lib,
  pkgs,
  inputs,
  fetchFromGitHub,
}:

let
  version = "1.2.0";
  python = pkgs.python313;

  src = fetchFromGitHub {
    owner = "oraios";
    repo = "serena";
    rev = "v${version}";
    hash = "sha256-ORjKX17WdikXoQgWVnorpeufvzf8qXP1eTcKtrF8MZA=";
  };

  workspace = inputs.uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = src;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (pkgs.callPackage inputs.pyproject-nix.build.packages {
      inherit python;
    }).overrideScope
      (
        lib.composeManyExtensions [
          inputs.pyproject-build-systems.overlays.default
          overlay
          (final: prev: {
            "proxy-tools" = prev."proxy-tools".overrideAttrs (old: {
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                final.setuptools
                final.wheel
              ];
            });
          })
        ]
      );

  serenaEnv = pythonSet.mkVirtualEnv "serena-env" workspace.deps.default;
in
pkgs.symlinkJoin {
  name = "serena-${version}";

  paths = [
    serenaEnv
  ];

  nativeBuildInputs = [
    pkgs.makeWrapper
  ];

  postBuild = ''
    rm -f \
      "$out/bin/python" \
      "$out/bin/python3" \
      "$out/bin/python3.13"

    wrapProgram "$out/bin/serena" \
      --prefix PATH : ${lib.makeBinPath [
        pkgs.git
        pkgs.ripgrep
        pkgs.fd
        pkgs.nodejs_22
      ]}

    if [[ -x "$out/bin/serena-hooks" ]]; then
      wrapProgram "$out/bin/serena-hooks" \
        --prefix PATH : ${lib.makeBinPath [
          pkgs.git
          pkgs.ripgrep
          pkgs.fd
          pkgs.nodejs_22
        ]}
    fi
  '';

  meta = with lib; {
    description = "Semantic code retrieval and editing MCP toolkit";
    homepage = "https://github.com/oraios/serena";
    license = licenses.mit;
    mainProgram = "serena";
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
