# NixOS Secure Boot Management Module

A comprehensive NixOS module for managing secure boot using systemd-ukify for key generation and systemd-sbsign for signing EFI binaries.

## Features

- **Automated Key Generation**: Generate secure boot keys (PK, KEK, db, dbx) using OpenSSL
- **Binary Signing**: Sign EFI binaries including kernels, initrd, and bootloaders using sbsigntool
- **Unified Kernel Images (UKI)**: Build and sign unified kernel images with systemd-ukify
- **Key Backup**: Automated encrypted backups of secure boot keys
- **Monitoring**: Track secure boot status and configuration
- **Helper Commands**: Convenient shell aliases for common operations

## Quick Start

### Using as a Flake Module

Add to your `flake.nix`:

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
        ./configuration.nix
      ];
    };
  };
}
```

Then in your `configuration.nix`:

```nix
{
  secureboot.enable = true;
}
```

### Using Directly

```nix
{
  imports = [
    /path/to/modules/secure-boot
  ];

  secureboot.enable = true;
}
```

## Module Structure

```
modules/secure-boot/
├── default.nix          # Main module with imports and high-level options
├── key-generation.nix   # Key generation using OpenSSL
├── signing.nix          # Binary signing using sbsigntool and ukify
└── examples/
    ├── README.md        # Detailed usage examples
    ├── minimal.nix      # Minimal configuration
    ├── basic.nix        # Basic configuration
    └── advanced.nix     # Advanced configuration
```

## Configuration Options

### secureboot.enable

Enable secure boot management system.

**Type**: boolean
**Default**: `false`

### secureboot.keyGeneration

Options for key generation.

#### secureboot.keyGeneration.enable

Enable secure boot key generation.

**Type**: boolean
**Default**: `false`

#### secureboot.keyGeneration.keyDirectory

Directory where secure boot keys will be stored.

**Type**: path
**Default**: `/etc/secureboot/keys`

#### secureboot.keyGeneration.keyTypes

Types of keys to generate.

**Type**: list of enum ["PK" "KEK" "db" "dbx"]
**Default**: `[ "PK" "KEK" "db" ]`

#### secureboot.keyGeneration.commonName

Common name for the certificate.

**Type**: string
**Default**: `config.networking.hostName or "localhost"`

#### secureboot.keyGeneration.organizationName

Organization name for the certificate.

**Type**: string
**Default**: `"NixOS Secure Boot"`

#### secureboot.keyGeneration.countryCode

Country code for the certificate (2 letters).

**Type**: string
**Default**: `"US"`

#### secureboot.keyGeneration.keySize

RSA key size in bits.

**Type**: integer
**Default**: `4096`

#### secureboot.keyGeneration.validityDays

Certificate validity period in days.

**Type**: integer
**Default**: `3650` (10 years)

#### secureboot.keyGeneration.autoGenerate

Automatically generate keys if they don't exist during system activation.

**Type**: boolean
**Default**: `false`

### secureboot.signing

Options for binary signing.

#### secureboot.signing.enable

Enable secure boot binary signing.

**Type**: boolean
**Default**: `false`

#### secureboot.signing.keyPath

Path to the private key for signing.

**Type**: path
**Default**: `"${keyGeneration.keyDirectory}/db.key"`

#### secureboot.signing.certPath

Path to the certificate for signing.

**Type**: path
**Default**: `"${keyGeneration.keyDirectory}/db.crt"`

#### secureboot.signing.signKernel

Automatically sign the kernel during system activation.

**Type**: boolean
**Default**: `true`

#### secureboot.signing.signInitrd

Sign initrd images.

**Type**: boolean
**Default**: `true`

#### secureboot.signing.signBootloaderFiles

Sign bootloader EFI files (systemd-boot, GRUB).

**Type**: boolean
**Default**: `true`

#### secureboot.signing.additionalBinaries

Additional EFI binaries to sign.

**Type**: list of paths
**Default**: `[]`

#### secureboot.signing.signedBinaryDirectory

Directory to store signed binaries.

**Type**: path
**Default**: `/boot/EFI/signed`

#### secureboot.signing.ukifyOptions

Additional options to pass to systemd-ukify.

**Type**: list of strings
**Default**: `[]`

#### secureboot.signing.autoSignOnBoot

Automatically sign binaries on system boot.

**Type**: boolean
**Default**: `false`

### secureboot.backup

Options for key backup.

#### secureboot.backup.enable

Enable automatic backup of secure boot keys.

**Type**: boolean
**Default**: `false`

#### secureboot.backup.directory

Directory for key backups.

**Type**: path
**Default**: `/var/lib/secureboot/backup`

#### secureboot.backup.encryptBackup

Encrypt key backups.

**Type**: boolean
**Default**: `true`

### secureboot.monitoring

Options for monitoring.

#### secureboot.monitoring.enable

Enable secure boot status monitoring.

**Type**: boolean
**Default**: `false`

#### secureboot.monitoring.checkInterval

How often to check secure boot status (systemd timer format).

**Type**: string
**Default**: `"daily"`

### secureboot.enrollKeys

Automatically enroll secure boot keys into the firmware.

**Type**: boolean
**Default**: `false`

**WARNING**: This will replace existing keys in your firmware. Only enable this if you understand the implications.

## Available Commands

When the module is enabled, the following commands are available:

### Key Generation

- `generate-secureboot-keys` - Generate secure boot keys
- `list-secureboot-keys` - List generated keys

### Signing

- `sign-efi-binary <binary> [output]` - Sign an EFI binary
- `build-uki [kernel] [initrd] [output]` - Build and sign a unified kernel image
- `sign-boot-files` - Sign all configured boot files
- `verify-efi-signature <binary>` - Verify signature on an EFI binary

### Management

- `secureboot-status` - Check secure boot status
- `secureboot-backup` - Backup secure boot keys
- `secureboot-enroll-keys` - Display key enrollment instructions

## Usage Workflow

### 1. Generate Keys

```bash
sudo generate-secureboot-keys
sudo list-secureboot-keys
```

### 2. Build and Sign Unified Kernel Image

```bash
sudo build-uki
```

Or with custom paths:

```bash
sudo build-uki /run/current-system/kernel /run/current-system/initrd /boot/EFI/signed/nixos.efi
```

### 3. Sign Additional Binaries

```bash
sudo sign-efi-binary /boot/EFI/systemd/systemd-bootx64.efi
sudo sign-boot-files
```

### 4. Verify Signatures

```bash
sudo verify-efi-signature /boot/EFI/signed/nixos.efi
```

### 5. Check Status

```bash
secureboot-status
```

### 6. Enroll Keys in Firmware

This step must be done manually through your BIOS/UEFI interface:

1. Boot into BIOS/UEFI setup
2. Navigate to Secure Boot settings
3. Clear existing keys (enter Setup Mode)
4. Import your generated keys from `/etc/secureboot/keys/`:
   - `PK.cer` (Platform Key)
   - `KEK.cer` (Key Exchange Key)
   - `db.cer` (Signature Database)
5. Enable Secure Boot
6. Save and reboot

For detailed instructions, run:

```bash
sudo secureboot-enroll-keys
```

### 7. Backup Keys

```bash
sudo secureboot-backup
```

## Security Considerations

### Key Storage

- Keys are stored with restrictive permissions (700 for directory, 600 for private keys)
- Consider storing keys on encrypted filesystems
- Keep backups in a secure, offline location

### Testing

- Test the entire process in a virtual machine first
- Ensure you can boot into the BIOS/UEFI to disable secure boot if needed
- Keep a bootable USB drive with your keys for recovery

### Recovery

If you lose access to your system:

1. Boot into BIOS/UEFI
2. Disable Secure Boot
3. Boot normally
4. Restore keys from backup
5. Re-sign binaries
6. Re-enable Secure Boot

### Best Practices

1. **Never lose your keys**: Keep encrypted backups in multiple secure locations
2. **Document your process**: Keep notes on how you enrolled keys
3. **Test regularly**: Verify that your setup works after updates
4. **Use strong keys**: The default 4096-bit RSA keys are recommended
5. **Monitor regularly**: Enable monitoring to track secure boot status
6. **Backup before changes**: Always backup keys before making changes

## Troubleshooting

### Keys not generating

**Problem**: Keys are not being created
**Solution**:
- Check permissions on key directory
- Review systemd service logs: `journalctl -u generate-secureboot-keys`
- Ensure OpenSSL is installed

### Signing fails

**Problem**: Binary signing fails
**Solution**:
- Verify keys exist: `sudo list-secureboot-keys`
- Check key permissions
- Ensure the binary is a valid EFI file
- Review error messages in logs

### Boot fails after enrolling keys

**Problem**: System won't boot after enabling secure boot
**Solution**:
1. Boot into BIOS and disable Secure Boot temporarily
2. Boot into NixOS
3. Verify signed binaries: `ls -lh /boot/EFI/signed/`
4. Check boot configuration: `efibootmgr -v`
5. Re-sign binaries if needed
6. Re-enable Secure Boot

### Permission denied

**Problem**: Commands fail with permission errors
**Solution**:
- Most commands require root/sudo access
- Check file permissions: `sudo ls -la /etc/secureboot/keys/`

### Secure boot status shows disabled

**Problem**: Secure boot appears disabled after enrollment
**Solution**:
- Verify keys are enrolled in BIOS
- Check that binaries are signed
- Ensure boot configuration points to signed binaries
- Review BIOS secure boot settings

## Technical Details

### Key Generation

Keys are generated using OpenSSL with the following characteristics:

- **Algorithm**: RSA
- **Key Size**: 4096 bits (configurable)
- **Format**: PEM (private key and certificate) + DER (for UEFI)
- **Validity**: 10 years (configurable)

### Signing Process

Binary signing uses sbsigntool:

1. Read the EFI binary
2. Sign with the db private key
3. Embed signature in the binary
4. Output signed binary

### Unified Kernel Images (UKI)

UKI creation uses systemd-ukify:

1. Combine kernel, initrd, and cmdline
2. Sign the unified image
3. Output a single bootable EFI file

### File Locations

- **Keys**: `/etc/secureboot/keys/`
- **Signed Binaries**: `/boot/EFI/signed/`
- **Backups**: `/var/lib/secureboot/backup/`
- **Helper Scripts**: `/etc/secureboot/`

## Integration with NixOS

### Boot Loaders

This module works with:

- **systemd-boot**: Recommended for best integration
- **GRUB**: Supported with additional configuration
- **Custom bootloaders**: Sign EFI binaries manually

### Updates

After system updates:

1. Keys are preserved in `/etc/secureboot/keys/`
2. Re-sign binaries with: `sudo sign-boot-files`
3. Or enable `autoSignOnBoot` for automatic signing

### Declarative Configuration

All settings are declarative in your NixOS configuration. Changes take effect on `nixos-rebuild switch`.

## Contributing

Issues and pull requests welcome at: https://github.com/sachesi/flake-repo

## License

This module is part of the sachesi/flake-repo project.

## References

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [systemd-ukify](https://www.freedesktop.org/software/systemd/man/ukify.html)
- [sbsigntool](https://git.kernel.org/pub/scm/linux/kernel/git/jejb/sbsigntools.git)
- [UEFI Secure Boot Specification](https://uefi.org/specifications)
- [Linux Secure Boot Documentation](https://www.kernel.org/doc/html/latest/admin-guide/securelevel.html)

## Credits

Developed for the sachesi/flake-repo project to provide a comprehensive secure boot management solution for NixOS.
