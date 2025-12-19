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
        desktop-thumbnailer = pkgs.callPackage ./pkgs/desktop-thumbnailer/package.nix { };
        custom-icons = pkgs.callPackage ./pkgs/custom-icons/package.nix { };
        libre-menu-editor = pkgs.callPackage ./pkgs/libre-menu-editor/package.nix { };

      in
      {
        packages = {
          default = desktop-thumbnailer;
          desktop-thumbnailer = desktop-thumbnailer;
          custom-icons = custom-icons;
          libre-menu-editor = libre-menu-editor;

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
          libre-menu-editor = flake-utils.lib.mkApp {
            drv = libre-menu-editor;
            name = "libre-menu-editor";
          };
        };
      }
    );
}
