# Basic Secure Boot Configuration
# A typical configuration for most users

{ config, pkgs, ... }:

{
  imports = [
    # Import the secure boot module
  ];

  secureboot = {
    enable = true;

    keyGeneration = {
      enable = true;
      autoGenerate = true;  # Generate keys automatically if they don't exist

      # Customize certificate details
      commonName = "my-nixos-system";
      organizationName = "Home Lab";
      countryCode = "US";

      # Key configuration
      keySize = 4096;
      validityDays = 3650;  # 10 years
    };

    signing = {
      enable = true;
      signKernel = true;
      signInitrd = true;
      signBootloaderFiles = true;
      autoSignOnBoot = false;  # Manual signing for better control
    };

    # Enable monitoring to track secure boot status
    monitoring = {
      enable = true;
      checkInterval = "daily";
    };
  };

  # Optional: Add informative message on login
  environment.interactiveShellInit = ''
    echo "Secure Boot is configured. Use 'secureboot-status' to check status."
  '';
}
