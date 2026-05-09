# Advanced Secure Boot Configuration
# A comprehensive configuration with all features enabled

{ config, pkgs, ... }:

{
  imports = [
    # Import the secure boot module
  ];

  secureboot = {
    enable = true;

    # Key Generation Configuration
    keyGeneration = {
      enable = true;
      autoGenerate = true;

      # Custom key storage location
      keyDirectory = "/etc/secureboot/keys";

      # Generate all standard key types
      keyTypes = [ "PK" "KEK" "db" ];

      # Certificate details
      commonName = "production-server.example.com";
      organizationName = "Example Corporation";
      countryCode = "US";

      # Strong key parameters
      keySize = 4096;
      validityDays = 3650;  # 10 years
    };

    # Signing Configuration
    signing = {
      enable = true;

      # Custom key paths (optional, defaults are fine)
      keyPath = "/etc/secureboot/keys/db.key";
      certPath = "/etc/secureboot/keys/db.crt";

      # What to sign
      signKernel = true;
      signInitrd = true;
      signBootloaderFiles = true;
      autoSignOnBoot = false;  # Manual signing recommended for production

      # Additional EFI binaries to sign
      additionalBinaries = [
        "/boot/EFI/systemd/systemd-bootx64.efi"
        "/boot/EFI/BOOT/BOOTX64.EFI"
      ];

      # Directory for signed binaries
      signedBinaryDirectory = "/boot/EFI/signed";

      # UKI (Unified Kernel Image) options
      ukifyOptions = [
        "--splash=/etc/secureboot/splash.bmp"
        "--cmdline=quiet loglevel=3 rd.systemd.show_status=auto"
      ];
    };

    # Backup Configuration
    backup = {
      enable = true;
      directory = "/var/lib/secureboot/backup";
      encryptBackup = true;  # Encrypt backups with GPG
    };

    # Monitoring Configuration
    monitoring = {
      enable = true;
      checkInterval = "daily";  # Check secure boot status daily
    };

    # Key enrollment (disabled by default for safety)
    # enrollKeys = false;  # Enable only when ready to enroll
  };

  # Additional system configuration for secure boot
  boot = {
    # Use systemd-boot for better secure boot integration
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };

    # Enable latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Security hardening
  security = {
    # Protect kernel logs
    dmesg.restrict = true;

    # Enable AppArmor or SELinux for additional security
    # apparmor.enable = true;
  };

  # Useful packages for secure boot management
  environment.systemPackages = with pkgs; [
    efibootmgr
    efivar
    sbsigntool
    openssl
    gnupg  # For backup encryption
  ];

  # Create a systemd timer to check for unsigned binaries
  systemd.services.check-unsigned-binaries = {
    description = "Check for Unsigned EFI Binaries";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      echo "Checking for unsigned EFI binaries in /boot..."
      ${pkgs.findutils}/bin/find /boot -name "*.efi" -type f | while read file; do
        if ! ${pkgs.sbsigntool}/bin/sbverify --list "$file" >/dev/null 2>&1; then
          echo "WARNING: Unsigned binary found: $file"
        fi
      done
    '';
  };

  systemd.timers.check-unsigned-binaries = {
    description = "Timer for Checking Unsigned Binaries";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "weekly";
      Persistent = true;
    };
  };
}
