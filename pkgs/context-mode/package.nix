{
  lib,
  stdenv,
  fetchFromGitHub,
  nodejs_22,
  bun,
  makeWrapper,
  python3,
  pkg-config,
  sqlite,
}:

let
  nodeModules = stdenv.mkDerivation rec {
    pname = "context-mode-node-modules";
    version = "1.0.103";

    src = fetchFromGitHub {
      owner = "mksglu";
      repo = "context-mode";
      rev = "v${version}";
      hash = "sha256-Yv0rQITaESPqcxCB73NNynFpQkkFB0qTx4aTvsE9/xE=";
    };

    nativeBuildInputs = [
      bun
      nodejs_22
      python3
      pkg-config
    ];

    buildInputs = [
      sqlite
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      bun install --no-progress --frozen-lockfile
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      rm -rf node_modules/.cache
      mkdir -p "$out"
      cp -r node_modules "$out/"
      runHook postInstall
    '';

    outputHashMode = "recursive";
    outputHash = "sha256-sdhKDBlzPk4GpuCAsdaqx7aaLqPJQQYtirUTFq9077w=";
  };
in
stdenv.mkDerivation rec {
  pname = "context-mode";
  version = "1.0.103";

  src = fetchFromGitHub {
    owner = "mksglu";
    repo = "context-mode";
    rev = "v${version}";
    hash = "sha256-Yv0rQITaESPqcxCB73NNynFpQkkFB0qTx4aTvsE9/xE=";
  };

  nativeBuildInputs = [
    nodejs_22
    bun
    makeWrapper
    python3
    pkg-config
  ];

  buildInputs = [
    sqlite
  ];

  postPatch = ''
    # Avoid home-directory mutations from the upstream postinstall hook.
    node - <<'EOF'
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync("package.json", "utf8"));
    if (pkg.scripts) delete pkg.scripts.postinstall;
    fs.writeFileSync("package.json", JSON.stringify(pkg, null, 2) + "\n");
    EOF

    cp -r ${nodeModules}/node_modules ./node_modules
    patchShebangs node_modules
  '';

  buildPhase = ''
    runHook preBuild
    bun run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib/context-mode"

    cp -r \
      package.json \
      cli.bundle.mjs \
      server.bundle.mjs \
      start.mjs \
      build \
      hooks \
      configs \
      skills \
      .claude-plugin \
      .openclaw-plugin \
      .mcp.json \
      openclaw.plugin.json \
      node_modules \
      "$out/lib/context-mode/"

    makeWrapper ${nodejs_22}/bin/node "$out/bin/context-mode" \
      --add-flags "$out/lib/context-mode/cli.bundle.mjs" \
      --prefix PATH : ${lib.makeBinPath [
        bun
        nodejs_22
      ]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Context window optimization MCP server and hooks";
    homepage = "https://github.com/mksglu/context-mode";
    license = licenses.elastic20;
    mainProgram = "context-mode";
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
