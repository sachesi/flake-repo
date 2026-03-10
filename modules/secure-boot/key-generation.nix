{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.secureboot.keyGeneration;
in
{
  options.secureboot.keyGeneration = {
    enable = mkEnableOption "secure boot key generation using systemd-ukify";

    keyDirectory = mkOption {
      type = types.path;
      default = "/etc/secureboot/keys";
      description = "Directory where secure boot keys will be stored";
    };

    keyTypes = mkOption {
      type = types.listOf (types.enum [ "PK" "KEK" "db" "dbx" ]);
      default = [ "PK" "KEK" "db" ];
      description = "Types of keys to generate (Platform Key, Key Exchange Key, Signature Database, Forbidden Signature Database)";
    };

    commonName = mkOption {
      type = types.str;
      default = config.networking.hostName or "localhost";
      description = "Common name for the certificate";
    };

    organizationName = mkOption {
      type = types.str;
      default = "NixOS Secure Boot";
      description = "Organization name for the certificate";
    };

    countryCode = mkOption {
      type = types.str;
      default = "US";
      description = "Country code for the certificate (2 letters)";
    };

    keySize = mkOption {
      type = types.int;
      default = 4096;
      description = "RSA key size in bits";
    };

    validityDays = mkOption {
      type = types.int;
      default = 3650;
      description = "Certificate validity period in days (default: 10 years)";
    };

    autoGenerate = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically generate keys if they don't exist during system activation";
    };
  };

  config = mkIf cfg.enable {
    # Ensure systemd-ukify is available
    environment.systemPackages = with pkgs; [
      systemd
      openssl
    ];

    # Create activation script for key generation
    system.activationScripts.generateSecureBootKeys = mkIf cfg.autoGenerate (
      stringAfter [ "etc" ] ''
        echo "Checking secure boot key generation..."

        # Create key directory if it doesn't exist
        mkdir -p ${cfg.keyDirectory}
        chmod 700 ${cfg.keyDirectory}

        # Function to generate a key pair if it doesn't exist
        generate_key() {
          local key_type=$1
          local key_file="${cfg.keyDirectory}/$key_type.key"
          local cert_file="${cfg.keyDirectory}/$key_type.crt"

          if [ ! -f "$key_file" ] || [ ! -f "$cert_file" ]; then
            echo "Generating $key_type secure boot key..."

            # Generate private key
            ${pkgs.openssl}/bin/openssl req -new -x509 \
              -newkey rsa:${toString cfg.keySize} \
              -keyout "$key_file" \
              -out "$cert_file" \
              -days ${toString cfg.validityDays} \
              -nodes \
              -subj "/C=${cfg.countryCode}/O=${cfg.organizationName}/CN=${cfg.commonName} $key_type"

            # Set secure permissions
            chmod 600 "$key_file"
            chmod 644 "$cert_file"

            # Generate DER format for UEFI
            ${pkgs.openssl}/bin/openssl x509 -in "$cert_file" \
              -out "${cfg.keyDirectory}/$key_type.cer" \
              -outform DER

            echo "Generated $key_type key pair successfully"
          else
            echo "$key_type key pair already exists, skipping generation"
          fi
        }

        # Generate keys for each requested type
        ${concatMapStringsSep "\n" (keyType: ''
          generate_key "${keyType}"
        '') cfg.keyTypes}

        echo "Secure boot key generation check completed"
      ''
    );

    # Create a systemd service for manual key generation
    systemd.services.generate-secureboot-keys = {
      description = "Generate Secure Boot Keys";
      wantedBy = [ ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        echo "Generating secure boot keys..."

        mkdir -p ${cfg.keyDirectory}
        chmod 700 ${cfg.keyDirectory}

        generate_key() {
          local key_type=$1
          local key_file="${cfg.keyDirectory}/$key_type.key"
          local cert_file="${cfg.keyDirectory}/$key_type.crt"

          if [ ! -f "$key_file" ] || [ ! -f "$cert_file" ]; then
            echo "Generating $key_type secure boot key..."

            ${pkgs.openssl}/bin/openssl req -new -x509 \
              -newkey rsa:${toString cfg.keySize} \
              -keyout "$key_file" \
              -out "$cert_file" \
              -days ${toString cfg.validityDays} \
              -nodes \
              -subj "/C=${cfg.countryCode}/O=${cfg.organizationName}/CN=${cfg.commonName} $key_type"

            chmod 600 "$key_file"
            chmod 644 "$cert_file"

            ${pkgs.openssl}/bin/openssl x509 -in "$cert_file" \
              -out "${cfg.keyDirectory}/$key_type.cer" \
              -outform DER

            echo "Generated $key_type key pair successfully"
          else
            echo "$key_type key pair already exists"
          fi
        }

        ${concatMapStringsSep "\n" (keyType: ''
          generate_key "${keyType}"
        '') cfg.keyTypes}

        echo "Key generation completed"
      '';
    };

    # Provide helper commands
    environment.shellAliases = {
      generate-secureboot-keys = "sudo systemctl start generate-secureboot-keys";
      list-secureboot-keys = "sudo ls -lh ${cfg.keyDirectory}";
    };
  };
}
