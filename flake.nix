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
        dethumb = pkgs.callPackage ./pkgs/dethumb/package.nix { };
        custom-icons = pkgs.callPackage ./pkgs/custom-icons/package.nix { };
        libre-menu-editor = pkgs.callPackage ./pkgs/libre-menu-editor/package.nix { };

      in
      {
        packages = {
          default = dethumb;
          dethumb = dethumb;
          custom-icons = custom-icons;
          libre-menu-editor = libre-menu-editor;

        };

        customPackages = {
          default = flake-utils.lib.mkApp {
            drv = dethumb;
            name = "dethumb";
          };
          dethumb = flake-utils.lib.mkApp {
            drv = dethumb;
            name = "dethumb";
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
