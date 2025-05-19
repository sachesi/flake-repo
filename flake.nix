{
  description = "sachesi packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays;
        };
        rustToolchain = pkgs.rust-bin.stable.latest.default;
        desktop-thumbnailer = pkgs.callPackage ./pkgs/desktop-thumbnailer/package.nix {
          inherit pkgs rustToolchain;
        };
        custom-icons = pkgs.callPackage ./pkgs/custom-icons/package.nix { };
        apparmor-d = pkgs.callPackage ./pkgs/apparmor-d/package.nix { };
      in
      {
        packages = {
          default = desktop-thumbnailer;
          desktop-thumbnailer = desktop-thumbnailer;
          custom-icons = custom-icons;
          apparmor-d = apparmor-d;
        };

        customPackages = {
          default = flake-utils.lib.mkApp {
            drv = desktop-thumbnailer;
            name = "desktop-thumbnailer";
          };
          desktop-thumbnailer = flake-utils.lib.mkApp {
            drv = desktop-thumbnailer;
            name = "desktop-thumbnailer";
          };
          custom-icons = flake-utils.lib.mkApp {
            drv = custom-icons;
            name = "custom-icons";
          };
          apparmor-d = flake-utils.lib.mkApp {
            drv = apparmor-d;
            name = "apparmor-d";
          };
        };
      }
    );
}
