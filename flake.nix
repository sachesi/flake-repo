{
  description = "sachesi packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    uv2nix.url = "github:pyproject-nix/uv2nix";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-build-systems.url = "github:pyproject-nix/build-system-pkgs";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      rust-overlay,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          (import rust-overlay)
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
          config.allowUnfree = true;
        };

        dethumb = pkgs.callPackage ./pkgs/dethumb/package.nix { };
        custom-icons = pkgs.callPackage ./pkgs/custom-icons/package.nix { };
        libre-menu-editor = pkgs.callPackage ./pkgs/libre-menu-editor/package.nix { };
        protonupd = pkgs.callPackage ./pkgs/protonupd/package.nix { };
        context-mode = pkgs.callPackage ./pkgs/context-mode/package.nix { };
        serena = pkgs.callPackage ./pkgs/serena/package.nix {
          inherit inputs;
        };
      in
      {
        packages = {
          default = dethumb;

          dethumb = dethumb;
          custom-icons = custom-icons;
          libre-menu-editor = libre-menu-editor;
          protonupd = protonupd;
          context-mode = context-mode;
          serena = serena;
        };

        apps = {
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

          protonupd = flake-utils.lib.mkApp {
            drv = protonupd;
            name = "protonupd";
          };

          context-mode = flake-utils.lib.mkApp {
            drv = context-mode;
            name = "context-mode";
          };

          serena = flake-utils.lib.mkApp {
            drv = serena;
            name = "serena";
          };
        };
      }
    );
}
