# Sachesi NixOS Packages and Modules

A collection of NixOS packages and modules maintained by sachesi.

## Packages

This flake provides the following packages:

- **desktop-thumbnailer**: A lightweight .desktop file thumbnailer (Rust, GPLv3)
- **custom-icons**: Custom icon sets for applications
- **libre-menu-editor**: A GNOME menu editor written in Python (GPLv3+)

## NixOS Modules

### Secure Boot Management

A comprehensive secure boot management module using systemd-ukify and systemd-sbsign.

**Location**: `modules/secure-boot/`

**Features**:
- Automated key generation (PK, KEK, db, dbx)
- EFI binary signing with sbsigntool
- Unified Kernel Image (UKI) building with systemd-ukify
- Automated key backups with encryption
- Secure boot status monitoring
- Helper commands for common operations

**Quick Start**:

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

For detailed documentation, see [modules/secure-boot/README.md](modules/secure-boot/README.md).

## Usage

### As a Flake

Add this repository to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-repo.url = "github:sachesi/flake-repo";
  };

  outputs = { self, nixpkgs, flake-repo, ... }: {
    # Use packages
    packages.x86_64-linux.default = flake-repo.packages.x86_64-linux.desktop-thumbnailer;

    # Use modules
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

### Available Outputs

- `packages.<system>.desktop-thumbnailer` - Desktop thumbnailer package
- `packages.<system>.custom-icons` - Custom icons package
- `packages.<system>.libre-menu-editor` - Libre menu editor package
- `nixosModules.secureboot` - Secure boot management module
- `nixosModules.default` - Default module (secure boot)

## Development

### Building Packages

```bash
# Build desktop-thumbnailer
nix build .#desktop-thumbnailer

# Build custom-icons
nix build .#custom-icons

# Build libre-menu-editor
nix build .#libre-menu-editor
```

### Testing Modules

```bash
# Check flake
nix flake check

# Show flake outputs
nix flake show
```

## License

- **desktop-thumbnailer**: GPLv3
- **custom-icons**: Free license
- **libre-menu-editor**: GPLv3+
- **secure-boot module**: Part of this flake repository

See [LICENSE](LICENSE) for details.

## Contributing

Issues and pull requests are welcome!

## Author

**sachesi**
- Email: sachesi.bb.passp@proton.me
- GitHub: [@sachesi](https://github.com/sachesi)

## Links

- Repository: https://github.com/sachesi/flake-repo
- Issues: https://github.com/sachesi/flake-repo/issues
