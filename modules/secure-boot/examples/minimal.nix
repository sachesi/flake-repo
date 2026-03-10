# Minimal Secure Boot Configuration
# This is the simplest possible configuration to enable secure boot management

{ config, pkgs, ... }:

{
  imports = [
    # Import the secure boot module
    # Adjust path based on your setup:
    # - For flake: inputs.flake-repo.nixosModules.secureboot
    # - For local: ../..
  ];

  # Enable secure boot with all defaults
  secureboot.enable = true;

  # That's it! The module will:
  # - Enable key generation
  # - Enable binary signing
  # - Use default paths and settings
}
