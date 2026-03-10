# NixOS Secure Boot Management - Example Configurations

This directory contains example configurations for setting up secure boot management
in NixOS using systemd-ukify and systemd-sbsign.

## Quick Start Example

The simplest configuration to get started:

```nix
# In your configuration.nix or flake
{
  imports = [
    # If using as a flake module:
    inputs.flake-repo.nixosModules.secureboot
    # Or directly:
    # ./modules/secure-boot
  ];

  secureboot.enable = true;
}
```

This enables secure boot management with all default settings.

## Basic Configuration

A more customized basic setup:

```nix
{
  imports = [
    inputs.flake-repo.nixosModules.secureboot
  ];

  secureboot = {
    enable = true;

    keyGeneration = {
      enable = true;
      autoGenerate = true;
      commonName = "my-nixos-machine";
      organizationName = "My Organization";
      countryCode = "US";
    };

    signing = {
      enable = true;
      signKernel = true;
      signInitrd = true;
      signBootloaderFiles = true;
    };

    monitoring = {
      enable = true;
      checkInterval = "daily";
    };
  };
}
```

## Advanced Configuration

A production-ready configuration with all features:

```nix
{
  imports = [
    inputs.flake-repo.nixosModules.secureboot
  ];

  secureboot = {
    enable = true;

    keyGeneration = {
      enable = true;
      autoGenerate = true;
      keyDirectory = "/etc/secureboot/keys";
      keyTypes = [ "PK" "KEK" "db" ];
      commonName = "production-server";
      organizationName = "ACME Corporation";
      countryCode = "US";
      keySize = 4096;
      validityDays = 3650; # 10 years
    };

    signing = {
      enable = true;
      signKernel = true;
      signInitrd = true;
      signBootloaderFiles = true;
      autoSignOnBoot = false; # Sign manually for more control

      # Additional EFI binaries to sign
      additionalBinaries = [
        "/boot/EFI/systemd/systemd-bootx64.efi"
        "/boot/EFI/BOOT/BOOTX64.EFI"
      ];

      # Custom ukify options
      ukifyOptions = [
        "--splash=/etc/secureboot/splash.bmp"
        "--cmdline=quiet loglevel=3"
      ];

      signedBinaryDirectory = "/boot/EFI/signed";
    };

    backup = {
      enable = true;
      directory = "/var/lib/secureboot/backup";
      encryptBackup = true;
    };

    monitoring = {
      enable = true;
      checkInterval = "daily";
    };
  };
}
```

## Flake Usage

If you're using this as a flake module, here's how to integrate it:

### In your flake.nix:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-repo.url = "github:sachesi/flake-repo";
  };

  outputs = { self, nixpkgs, flake-repo, ... }: {
    nixosConfigurations.my-machine = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        flake-repo.nixosModules.secureboot
        {
          secureboot.enable = true;
        }
      ];
    };
  };
}
```

## Manual Usage Steps

After enabling the module:

### 1. Generate Keys

```bash
# Keys will be auto-generated if autoGenerate = true
# Or generate manually:
generate-secureboot-keys

# Verify keys were created:
list-secureboot-keys
```

### 2. Build and Sign Unified Kernel Image

```bash
# Build a unified kernel image (UKI) with embedded signature:
build-uki

# Or specify custom paths:
build-uki /run/current-system/kernel /run/current-system/initrd /boot/EFI/signed/nixos.efi
```

### 3. Sign Additional Binaries

```bash
# Sign a specific EFI binary:
sign-efi-binary /boot/EFI/systemd/systemd-bootx64.efi

# Sign all configured boot files:
sign-boot-files
```

### 4. Verify Signatures

```bash
# Verify a signed binary:
verify-efi-signature /boot/EFI/signed/nixos.efi
```

### 5. Check Secure Boot Status

```bash
secureboot-status
```

### 6. Enroll Keys in Firmware

```bash
# This provides instructions for manual enrollment:
secureboot-enroll-keys
```

The actual enrollment must be done through your BIOS/UEFI interface:
1. Boot into BIOS/UEFI setup
2. Navigate to Secure Boot settings
3. Clear existing keys (enter Setup Mode)
4. Import your generated keys from `/etc/secureboot/keys/`:
   - PK.cer (Platform Key)
   - KEK.cer (Key Exchange Key)
   - db.cer (Signature Database)
5. Enable Secure Boot
6. Save and reboot

### 7. Backup Keys

```bash
# Create a backup:
secureboot-backup
```

## Security Best Practices

1. **Key Storage**: Keep your keys in a secure location with restricted permissions
2. **Backups**: Always maintain encrypted backups of your keys
3. **Testing**: Test in a VM before deploying to production systems
4. **Documentation**: Document your key enrollment process
5. **Recovery**: Keep a bootable USB with your keys for recovery
6. **Monitoring**: Enable monitoring to track secure boot status

## Troubleshooting

### Keys not generating
- Check permissions on key directory
- Verify systemd service logs: `journalctl -u generate-secureboot-keys`

### Signing fails
- Ensure keys exist and are readable
- Check file paths are correct
- Verify binary is a valid EFI file

### Boot fails after enrollment
- Boot into BIOS and disable Secure Boot temporarily
- Verify your signed binaries are in the correct location
- Check boot configuration with `efibootmgr`

### Permission denied errors
- Most commands require root/sudo access
- Check file permissions in key directory

## Additional Resources

- NixOS Manual: https://nixos.org/manual/nixos/stable/
- systemd-ukify: https://www.freedesktop.org/software/systemd/man/ukify.html
- sbsigntool: https://git.kernel.org/pub/scm/linux/kernel/git/jejb/sbsigntools.git
- UEFI Secure Boot: https://uefi.org/specifications
