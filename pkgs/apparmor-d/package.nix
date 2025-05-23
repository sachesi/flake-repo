{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "apparmor-d";
  version = "unstable-2025-05-19";

  src = fetchFromGitHub {
    rev = "86afef4920601f4e8babdfaf15d232ac5aed2979";
    owner = "roddhjav";
    repo = "apparmor.d";
    hash = "sha256-7drr8hlN4jYwgse99RHYpgqYUj+F3xIaGZ8VnphIJvY=";
  };

  doCheck = false;
  dontBuild = true;

  patches = [
    ./apparmor-d-paths.patch
    ./tunables-multiarch_d-profiles.patch
  ];

  installPhase = ''
    mkdir -p $out/etc
    cp -r apparmor.d $out/etc
  '';
}
