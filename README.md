# satrOS

**satrOS** is a lightweight, Arch Linux-based live operating system and installer project. The image is built with `archiso` and provides a ready-to-use live environment together with the Calamares graphical installer.

> satrOS is an independent project. It is not an official Arch Linux distribution.

## Current release

The current published image is **satrOS 2026.09.12** for `x86_64` systems.

Because the ISO is larger than the per-file limit accepted by GitHub Releases, it is published as two parts:

- `satros-2026.09.12-x86_64.iso.part-aa`
- `satros-2026.09.12-x86_64.iso.part-ab`
- `SHA256SUMS`

Download all three files from the release before starting the installation. The parts are ordered and must be joined together before the ISO can be used.

## Reconstructing the ISO

Linux, macOS, and WSL:

```bash
cat satros-2026.09.12-x86_64.iso.part-aa \\
    satros-2026.09.12-x86_64.iso.part-ab \\
    > satros-2026.09.12-x86_64.iso
```

Verify the downloaded parts and the reconstructed image:

```bash
sha256sum -c SHA256SUMS
sha256sum satros-2026.09.12-x86_64.iso
```

On Windows PowerShell, use:

```powershell
Get-Content .\\SHA256SUMS
cmd /c copy /b satros-2026.09.12-x86_64.iso.part-aa+satros-2026.09.12-x86_64.iso.part-ab satros-2026.09.12-x86_64.iso
Get-FileHash .\\satros-2026.09.12-x86_64.iso -Algorithm SHA256
```

The SHA-256 values in `SHA256SUMS` are authoritative. Do not boot or install an image whose checksum does not match.

## Writing the ISO to a USB drive

The reconstructed ISO is hybrid media intended for both BIOS and UEFI boot. Writing it to a USB drive erases the target device, so double-check the device path first.

On Linux:

```bash
lsblk
sudo umount /dev/sdX* 2>/dev/null || true
sudo dd if=satros-2026.09.12-x86_64.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

Replace `/dev/sdX` with the whole USB device, not a partition such as `/dev/sdX1`. After writing finishes, safely eject the drive:

```bash
sync
udisksctl power-off -b /dev/sdX
```

Rufus, balenaEtcher, Ventoy, and similar tools can also write or boot the reconstructed image. If a tool asks whether to use ISO or DD mode, DD mode is the safer choice for this hybrid image.

## Live environment and installation

1. Boot the USB drive in BIOS or UEFI mode.
2. Test hardware, networking, sound, and display in the live session.
3. Start the Calamares installer from the live desktop.
4. Select the locale, keyboard layout, target disk, users, network configuration, and optional packages.
5. Review the partitioning and bootloader settings carefully before confirming.
6. Reboot after the installer reports success and remove the USB drive.

The installer uses `pacman` for target packages and builds the installed system's initramfs with `mkinitcpio`. Network access is required during installation when packages or updates must be downloaded.

## Main components

- Arch Linux base and `archiso` live-image tooling
- Openbox desktop session
- Calamares graphical installer
- NetworkManager and common wired/wireless utilities
- Linux kernel, firmware, microcode, storage, filesystem, rescue, and diagnostic tools
- GRUB configuration for installed systems
- BIOS Syslinux boot and UEFI systemd-boot live boot paths
- Automatic CPU and GPU detection helpers
- `mkinitcpio`-based initramfs generation for the installed system

The package selection is maintained in [`packages.x86_64`](packages.x86_64). Live-root configuration lives under [`airootfs/`](airootfs/), while bootloader configuration is kept in [`grub/`](grub/) and [`syslinux/`](syslinux/).

## Building satrOS

Builds should be performed on an Arch Linux system, or in an environment that provides the Arch packaging toolchain. The build needs root-capable access for `mkarchiso` and enough free disk space for package caches, the temporary filesystem tree, and the final ISO.

Install the usual build dependencies first:

```bash
sudo pacman -S --needed archiso base-devel git
```

Then build from the repository root:

```bash
./build-iso.sh
```

The script:

1. Builds the local Calamares package from `packaging/calamares-bin/`.
2. Creates a temporary local pacman repository for that package.
3. Adds the local repository to an isolated build configuration.
4. Runs `mkarchiso` with the satrOS profile.

By default, temporary files are placed below `/tmp/satros-build` and the ISO is written to `/tmp/satros-build/out`. These locations can be changed without editing the script:

```bash
SATROS_BUILD_ROOT=/path/to/build \\
SATROS_OUTPUT_DIR=/path/to/output \\
./build-iso.sh
```

The build uses the current Arch repositories and mirrors, so the exact package versions and resulting image contents can change over time. For reproducible builds, pin the package repositories and record the build date, package database state, and checksums.

## Repository layout

```text
airootfs/       Files and configuration copied into the live filesystem
grub/           GRUB and loopback boot configuration
packaging/      Local PKGBUILD definitions, including Calamares
syslinux/       Syslinux boot configuration
build-iso.sh    End-to-end ISO build entry point
packages.x86_64 Package list for the live image
profiledef.sh  archiso profile and file permissions
pacman.conf     Base package repository configuration
```

Generated ISO files, build trees, package caches, VM output, and logs are intentionally excluded by [`.gitignore`](.gitignore). Release binaries belong in GitHub Releases rather than in the Git history.

## Development notes

- Keep generated output outside tracked source directories.
- Test both BIOS and UEFI boot paths after changing boot configuration.
- Test the Calamares flow in a virtual machine before installing on physical hardware.
- Verify that the installed system can regenerate its initramfs after kernel changes.
- Recalculate and publish SHA-256 checksums for every release image.
- Treat disk partitioning and raw USB writing as destructive operations.

## Project status

satrOS is an active development project. Hardware compatibility, package versions, installer behavior, and visual design may change between builds. Always back up important data before testing the installer.

## License and attribution

The repository contains project-specific configuration and scripts assembled around Arch Linux and archiso. Check individual files for their applicable license headers and upstream attribution. Arch Linux trademarks and project materials remain the property of their respective owners.
