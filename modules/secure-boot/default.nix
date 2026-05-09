{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.secureboot;
in
{
  imports = [
    ./key-generation.nix
    ./signing.nix
  ];

  options.secureboot = {
    enable = mkEnableOption "secure boot management system";

    enrollKeys = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Automatically enroll secure boot keys into the firmware.
        WARNING: This will replace existing keys in your firmware.
        Only enable this if you understand the implications.
      '';
    };

    backup = {
      enable = mkEnableOption "automatic backup of secure boot keys";

      directory = mkOption {
        type = types.path;
        default = "/var/lib/secureboot/backup";
        description = "Directory for key backups";
      };

      encryptBackup = mkOption {
        type = types.bool;
        default = true;
        description = "Encrypt key backups";
      };
    };

    monitoring = {
      enable = mkEnableOption "secure boot status monitoring";

      checkInterval = mkOption {
        type = types.str;
        default = "daily";
        description = "How often to check secure boot status (systemd timer format)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable the submodules
    secureboot.keyGeneration.enable = mkDefault true;
    secureboot.signing.enable = mkDefault true;

    # Ensure necessary packages are available
    environment.systemPackages = with pkgs; [
      systemd
      sbsigntool
      efibootmgr
      openssl
      efivar
    ];

    # Key backup service
    systemd.services.backup-secureboot-keys = mkIf cfg.backup.enable {
      description = "Backup Secure Boot Keys";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo "Backing up secure boot keys..."

        KEY_DIR="${config.secureboot.keyGeneration.keyDirectory}"
        BACKUP_DIR="${cfg.backup.directory}"

        if [ ! -d "$KEY_DIR" ]; then
          echo "Key directory does not exist, nothing to backup"
          exit 0
        fi

        mkdir -p "$BACKUP_DIR"
        chmod 700 "$BACKUP_DIR"

        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$BACKUP_DIR/secureboot_keys_$TIMESTAMP.tar"

        cd "$KEY_DIR"
        ${pkgs.gnutar}/bin/tar -cf "$BACKUP_FILE" ./*

        ${optionalString cfg.backup.encryptBackup ''
          echo "Encrypting backup..."
          ${pkgs.gnupg}/bin/gpg --symmetric --cipher-algo AES256 "$BACKUP_FILE"
          rm "$BACKUP_FILE"
          BACKUP_FILE="$BACKUP_FILE.gpg"
        ''}

        chmod 600 "$BACKUP_FILE"
        echo "Backup completed: $BACKUP_FILE"

        # Keep only last 5 backups
        cd "$BACKUP_DIR"
        ls -t | tail -n +6 | xargs -r rm
      '';
    };

    # Timer for automatic backups
    systemd.timers.backup-secureboot-keys = mkIf cfg.backup.enable {
      description = "Timer for Secure Boot Key Backup";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        Persistent = true;
      };
    };

    # Secure boot status monitoring service
    systemd.services.check-secureboot-status = mkIf cfg.monitoring.enable {
      description = "Check Secure Boot Status";
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        echo "Checking secure boot status..."

        # Check if secure boot is enabled
        if [ -f /sys/firmware/efi/efivars/SecureBoot-* ]; then
          SECUREBOOT_STATUS=$(od -An -t u1 /sys/firmware/efi/efivars/SecureBoot-* | awk '{print $NF}')
          if [ "$SECUREBOOT_STATUS" = "1" ]; then
            echo "Secure Boot is ENABLED"
          else
            echo "Secure Boot is DISABLED"
          fi
        else
          echo "Secure Boot status unavailable (not running UEFI or no permission)"
        fi

        # Check setup mode
        if [ -f /sys/firmware/efi/efivars/SetupMode-* ]; then
          SETUP_MODE=$(od -An -t u1 /sys/firmware/efi/efivars/SetupMode-* | awk '{print $NF}')
          if [ "$SETUP_MODE" = "1" ]; then
            echo "WARNING: System is in Setup Mode (keys not enrolled)"
          else
            echo "Setup Mode: Keys are enrolled"
          fi
        fi

        # List current boot configuration
        echo -e "\nCurrent boot configuration:"
        ${pkgs.efibootmgr}/bin/efibootmgr -v || echo "Could not read boot configuration"

        # Check signed binaries
        echo -e "\nChecking signed binaries in ${config.secureboot.signing.signedBinaryDirectory}:"
        if [ -d "${config.secureboot.signing.signedBinaryDirectory}" ]; then
          ls -lh "${config.secureboot.signing.signedBinaryDirectory}" || echo "No signed binaries found"
        else
          echo "Signed binary directory does not exist"
        fi
      '';
    };

    # Timer for monitoring
    systemd.timers.check-secureboot-status = mkIf cfg.monitoring.enable {
      description = "Timer for Secure Boot Status Check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.monitoring.checkInterval;
        Persistent = true;
      };
    };

    # Key enrollment service (careful with this!)
    systemd.services.enroll-secureboot-keys = mkIf cfg.enrollKeys {
      description = "Enroll Secure Boot Keys into Firmware";
      wantedBy = [ ];  # Never auto-start, must be manually triggered
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        echo "WARNING: This will enroll keys into your firmware!"
        echo "Make sure you have a backup of your existing keys."
        echo ""

        KEY_DIR="${config.secureboot.keyGeneration.keyDirectory}"

        if [ ! -d "$KEY_DIR" ]; then
          echo "Error: Key directory does not exist. Generate keys first."
          exit 1
        fi

        # Check if we're in setup mode
        if [ -f /sys/firmware/efi/efivars/SetupMode-* ]; then
          SETUP_MODE=$(od -An -t u1 /sys/firmware/efi/efivars/SetupMode-* | awk '{print $NF}')
          if [ "$SETUP_MODE" != "1" ]; then
            echo "Error: System is not in Setup Mode. Clear existing keys in BIOS first."
            exit 1
          fi
        else
          echo "Warning: Cannot determine Setup Mode status"
        fi

        # Enroll keys using efi-updatevar or similar
        echo "Key enrollment would happen here..."
        echo "This requires platform-specific implementation."
        echo ""
        echo "Manual steps:"
        echo "1. Enter BIOS/UEFI setup"
        echo "2. Clear existing Secure Boot keys (enter Setup Mode)"
        echo "3. Import the following keys from $KEY_DIR:"
        echo "   - PK.cer (Platform Key)"
        echo "   - KEK.cer (Key Exchange Key)"
        echo "   - db.cer (Signature Database)"
        echo "4. Enable Secure Boot"
      '';
    };

    # Add convenience commands
    environment.shellAliases = {
      secureboot-status = "sudo systemctl start check-secureboot-status && sudo journalctl -u check-secureboot-status -n 50";
      secureboot-backup = "sudo systemctl start backup-secureboot-keys";
      secureboot-enroll-keys = "sudo systemctl start enroll-secureboot-keys";
    };

    # Informational message on login
    environment.interactiveShellInit = ''
      # Secure Boot Management is enabled
      # Available commands:
      #   secureboot-status        - Check secure boot status
      #   generate-secureboot-keys - Generate secure boot keys
      #   sign-efi-binary         - Sign an EFI binary
      #   build-uki               - Build unified kernel image
      #   sign-boot-files         - Sign boot files
      #   secureboot-backup       - Backup secure boot keys
    '';

    # Documentation
    environment.etc."secureboot/README".text = ''
      NixOS Secure Boot Management
      ============================

      This system provides secure boot management using systemd-ukify and systemd-sbsign.

      Quick Start:
      -----------
      1. Generate keys:
         $ generate-secureboot-keys

      2. Check that keys were created:
         $ list-secureboot-keys

      3. Build and sign a unified kernel image:
         $ build-uki

      4. Sign additional EFI binaries:
         $ sign-efi-binary /path/to/binary.efi

      5. Enroll keys in firmware (manual process):
         $ secureboot-enroll-keys
         Follow the instructions to manually enroll keys in BIOS/UEFI

      6. Check secure boot status:
         $ secureboot-status

      Key Locations:
      -------------
      Keys are stored in: ${config.secureboot.keyGeneration.keyDirectory}
      Signed binaries in: ${config.secureboot.signing.signedBinaryDirectory}
      ${optionalString cfg.backup.enable "Backups in: ${cfg.backup.directory}"}

      Configuration:
      -------------
      See /etc/nixos/configuration.nix for module options:
        - secureboot.keyGeneration.*
        - secureboot.signing.*
        - secureboot.backup.*
        - secureboot.monitoring.*

      Security Notes:
      --------------
      - Keep your private keys secure and backed up
      - Never share your private keys
      - Test in a VM before deploying to production
      - Make sure you understand secure boot before enrolling keys
      - Keep a backup of your original firmware keys

      For more information, see the NixOS manual and systemd documentation.
    '';
  };
}
