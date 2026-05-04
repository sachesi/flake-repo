{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
  python3,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  pname = "caveman";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "v${version}";
    hash = "sha256-op4667BuHadUN24QQ6J9qjU65BPxMbxzr24JhC1w/M0=";
  };

  nativeBuildInputs = [
    nodejs_22
    python3
    makeWrapper
  ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    echo "Installing to $out"
    mkdir -p "$out/lib/caveman" "$out/bin"
    cp -r . "$out/lib/caveman/"

    # Wrap caveman-shrink MCP server
    echo "Wrapping caveman-shrink"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/caveman-shrink" \
      --add-flags "$out/lib/caveman/mcp-servers/caveman-shrink/index.js"

    # Wrap caveman-compress tool
    echo "Wrapping caveman-compress"
    makeWrapper ${python3}/bin/python3 "$out/bin/caveman-compress" \
      --add-flags "-m scripts" \
      --run "cd $out/lib/caveman/caveman-compress"

    # Provide a helper to list skills/hooks paths
    echo "Creating caveman-paths"
    cat > "$out/bin/caveman-paths" <<EOF
    #!/bin/sh
    echo "Skills: $out/lib/caveman/skills"
    echo "Hooks:  $out/lib/caveman/hooks"
EOF
    chmod +x "$out/bin/caveman-paths"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Claude Code skill that cuts 65% of tokens by talking like caveman";
    homepage = "https://github.com/JuliusBrussee/caveman";
    license = licenses.mit;
    mainProgram = "caveman-shrink";
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
