{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.secureboot.signing;
  keyGenCfg = config.secureboot.keyGeneration;
in
{
  options.secureboot.signing = {
    enable = mkEnableOption "secure boot binary signing using systemd-sbsign";

    keyPath = mkOption {
      type = types.path;
      default = "${keyGenCfg.keyDirectory}/db.key";
      description = "Path to the private key for signing";
    };

    certPath = mkOption {
      type = types.path;
      default = "${keyGenCfg.keyDirectory}/db.crt";
      description = "Path to the certificate for signing";
    };

    signKernel = mkOption {
      type = types.bool;
      default = true;
      description = "Automatically sign the kernel during system activation";
    };

    signInitrd = mkOption {
      type = types.bool;
      default = true;
      description = "Sign initrd images";
    };

    signBootloaderFiles = mkOption {
      type = types.bool;
      default = true;
      description = "Sign bootloader EFI files (systemd-boot, GRUB)";
    };

    additionalBinaries = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = "Additional EFI binaries to sign";
      example = literalExpression ''
        [
          "/boot/EFI/systemd/systemd-bootx64.efi"
          "/boot/EFI/BOOT/BOOTX64.EFI"
        ]
      '';
    };

    signedBinaryDirectory = mkOption {
      type = types.path;
      default = "/boot/EFI/signed";
      description = "Directory to store signed binaries";
    };

    ukifyOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional options to pass to systemd-ukify";
      example = [ "--splash=/path/to/splash.bmp" "--cmdline=quiet" ];
    };

    autoSignOnBoot = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically sign binaries on system boot";
    };
  };

  config = mkIf cfg.enable {
    # Ensure required tools are available
    environment.systemPackages = with pkgs; [
      systemd
      sbsigntool
      binutils
      efibootmgr
    ];

    # Helper script for signing EFI binaries
    environment.etc."secureboot/sign-efi-binary".source = pkgs.writeShellScript "sign-efi-binary" ''
      #!/usr/bin/env bash
      set -euo pipefail

      if [ $# -lt 1 ]; then
        echo "Usage: $0 <binary-path> [output-path]"
        exit 1
      fi

      BINARY_PATH="$1"
      OUTPUT_PATH="''${2:-$BINARY_PATH.signed}"

      if [ ! -f "${cfg.keyPath}" ]; then
        echo "Error: Private key not found at ${cfg.keyPath}"
        echo "Please generate keys first using: generate-secureboot-keys"
        exit 1
      fi

      if [ ! -f "${cfg.certPath}" ]; then
        echo "Error: Certificate not found at ${cfg.certPath}"
        exit 1
      fi

      if [ ! -f "$BINARY_PATH" ]; then
        echo "Error: Binary not found at $BINARY_PATH"
        exit 1
      fi

      echo "Signing $BINARY_PATH..."
      ${pkgs.sbsigntool}/bin/sbsign \
        --key "${cfg.keyPath}" \
        --cert "${cfg.certPath}" \
        --output "$OUTPUT_PATH" \
        "$BINARY_PATH"

      echo "Successfully signed binary: $OUTPUT_PATH"
    '';

    # Helper script for building and signing unified kernel images (UKI)
    environment.etc."secureboot/build-uki".source = pkgs.writeShellScript "build-uki" ''
      #!/usr/bin/env bash
      set -euo pipefail

      KERNEL_PATH="''${1:-/run/current-system/kernel}"
      INITRD_PATH="''${2:-/run/current-system/initrd}"
      OUTPUT_PATH="''${3:-${cfg.signedBinaryDirectory}/nixos-uki.efi}"

      if [ ! -f "$KERNEL_PATH" ]; then
        echo "Error: Kernel not found at $KERNEL_PATH"
        exit 1
      fi

      if [ ! -f "$INITRD_PATH" ]; then
        echo "Error: Initrd not found at $INITRD_PATH"
        exit 1
      fi

      echo "Building Unified Kernel Image..."
      mkdir -p "$(dirname "$OUTPUT_PATH")"

      # Build UKI with systemd-ukify
      ${pkgs.systemd}/bin/ukify build \
        --linux="$KERNEL_PATH" \
        --initrd="$INITRD_PATH" \
        ${optionalString (cfg.keyPath != null && cfg.certPath != null) ''
          --secureboot-private-key="${cfg.keyPath}" \
          --secureboot-certificate="${cfg.certPath}" \
        ''} \
        ${concatStringsSep " " cfg.ukifyOptions} \
        --output="$OUTPUT_PATH"

      echo "Successfully built and signed UKI: $OUTPUT_PATH"
    '';

    # Systemd service for signing boot files
    systemd.services.sign-boot-files = {
      description = "Sign Boot Files for Secure Boot";
      wantedBy = mkIf cfg.autoSignOnBoot [ "multi-user.target" ];
      after = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = with pkgs; [ systemd sbsigntool binutils coreutils findutils ];
      script = ''
        echo "Checking boot files for signing..."

        if [ ! -f "${cfg.keyPath}" ]; then
          echo "Warning: Private key not found, skipping signing"
          exit 0
        fi

        mkdir -p ${cfg.signedBinaryDirectory}

        sign_if_needed() {
          local input_file="$1"
          local output_file="$2"

          if [ ! -f "$input_file" ]; then
            echo "Warning: $input_file not found, skipping"
            return
          fi

          # Check if file needs signing (compare timestamps or signatures)
          if [ ! -f "$output_file" ] || [ "$input_file" -nt "$output_file" ]; then
            echo "Signing: $input_file -> $output_file"
            ${pkgs.sbsigntool}/bin/sbsign \
              --key "${cfg.keyPath}" \
              --cert "${cfg.certPath}" \
              --output "$output_file" \
              "$input_file"
          else
            echo "Already signed: $output_file"
          fi
        }

        # Sign bootloader files if requested
        ${optionalString cfg.signBootloaderFiles ''
          # Sign systemd-boot
          if [ -f /boot/EFI/systemd/systemd-bootx64.efi ]; then
            sign_if_needed /boot/EFI/systemd/systemd-bootx64.efi \
                          ${cfg.signedBinaryDirectory}/systemd-bootx64.efi
          fi

          # Sign GRUB
          if [ -f /boot/EFI/BOOT/BOOTX64.EFI ]; then
            sign_if_needed /boot/EFI/BOOT/BOOTX64.EFI \
                          ${cfg.signedBinaryDirectory}/BOOTX64.EFI
          fi
        ''}

        # Sign additional binaries
        ${concatMapStringsSep "\n" (binary: ''
          if [ -f "${binary}" ]; then
            sign_if_needed "${binary}" \
                          "${cfg.signedBinaryDirectory}/$(basename ${binary})"
          fi
        '') cfg.additionalBinaries}

        echo "Boot file signing completed"
      '';
    };

    # System activation script
    system.activationScripts.signSecureBootBinaries = mkIf (cfg.signKernel || cfg.signInitrd) (
      stringAfter [ "etc" ] ''
        echo "Checking secure boot binary signing..."

        if [ -f "${cfg.keyPath}" ] && [ -f "${cfg.certPath}" ]; then
          mkdir -p ${cfg.signedBinaryDirectory}

          ${optionalString cfg.signKernel ''
            if [ -f /run/current-system/kernel ]; then
              echo "Kernel found, signing can be done manually with sign-efi-binary command"
            fi
          ''}

          ${optionalString cfg.signInitrd ''
            if [ -f /run/current-system/initrd ]; then
              echo "Initrd found, UKI can be built manually with build-uki command"
            fi
          ''}
        else
          echo "Secure boot keys not found, skipping signing"
        fi
      ''
    );

    # Environment aliases for convenience
    environment.shellAliases = {
      sign-efi-binary = "sudo /etc/secureboot/sign-efi-binary";
      build-uki = "sudo /etc/secureboot/build-uki";
      sign-boot-files = "sudo systemctl start sign-boot-files";
      verify-efi-signature = "sudo ${pkgs.sbsigntool}/bin/sbverify --list";
    };

    # Add completion info
    environment.interactiveShellInit = ''
      # Secure boot signing helpers are available:
      #   sign-efi-binary <binary> [output] - Sign an EFI binary
      #   build-uki [kernel] [initrd] [output] - Build and sign a unified kernel image
      #   sign-boot-files - Sign all configured boot files
      #   verify-efi-signature <binary> - Verify signature on an EFI binary
    '';
  };
}
