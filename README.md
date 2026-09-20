# satrOS

**satrOS** is a lightweight, Arch Linux-based live operating system and installer project. The image is built with `archiso` and provides a ready-to-use live environment together with the Calamares graphical installer.

> satrOS is an independent project. It is not an official Arch Linux distribution.

## Current release

The current published image is **satrOS 2026.09.12** for `x86_64` systems, published as release **`v0.03`**.

Because the ISO is larger than the per-file limit accepted by GitHub Releases, it is published as two parts:

- `satros-2026.09.12-x86_64.iso.part-aa`
- `satros-2026.09.12-x86_64.iso.part-ab`
- `SHA256SUMS`

Download all three files from the release before starting the installation. The parts are ordered and must be joined together before the ISO can be used.

## What is included in v0.03

This release turns the satrOS profile into a more complete installable live image. The source tree now contains the full live boot path, a branded Calamares workflow, hardware-reporting helpers, an explicit package chooser, and an Arch-specific initramfs step for the installed system.

### Installer features added or enabled

- Branded satrOS Calamares workflow with locale, keyboard, partitioning, user, network, summary, and completion pages.
- Package selection screen (`packagechooserq`) before partitioning, so the user can choose the target kernel, desktop environment, browser, NVIDIA driver option, and extra applications.
- Pacman package installation through a dedicated `packages@pacman` instance with database refresh enabled.
- NetworkManager is enabled in the installed system by the Calamares services step.
- GRUB configuration and bootloader installation are included in the execution sequence.
- The installed system gets a new machine ID, generated `fstab`, locale and keyboard configuration, network configuration, hardware clock setup, and enabled system services.

### Hardware detection and driver behavior

The installer reports CPU and GPU information before installation:

- CPU vendor is read from `/proc/cpuinfo`.
- GPU controllers are read through `lspci` and classified as NVIDIA, AMD/ATI, Intel, or a known virtual GPU.
- The scripts report the result to Calamares and do not modify the running live session.
- GPU drivers remain an explicit package choice. Detection does not silently install a kernel module while the live environment is running.
- Intel and AMD microcode packages are present in the image; the CPU helper reports which vendor microcode is relevant.

### Installed-system initramfs

The installer now builds the initramfs for every installed kernel with `mkinitcpio`. Before doing so, the live-only `archiso.conf` drop-in is temporarily moved out of `mkinitcpio.conf.d`. This prevents an installed system from retaining a live-image mount configuration that refers to `/run/archiso/bootmnt` on subsequent boots.

### Boot and live-image changes

- The image is configured for both BIOS/Syslinux and UEFI/systemd-boot paths.
- The Syslinux live menu starts with a short timeout so the default entry boots quickly.
- satrOS branding is used consistently in `os-release`, the live issue, Calamares branding, hostname, and boot configuration.
- The build uses a local Calamares package repository created by `build-iso.sh`, so the image can include the project-specific Calamares package without committing generated packages to Git.

### Bootloop and session fixes

The previous live-session loop was traced to the login shell starting `startx`, the X session making Calamares its main process, and the shell starting X again when that process exited:

```text
autologin root -> login profile -> startx -> X/Openbox/Calamares
    -> X exits -> login shell exits -> autologin -> startx again
```

The current startup path breaks that cycle:

- `.bash_profile` and `.zprofile` start X only on `tty1` and only when `DISPLAY` is unset.
- `.profile` is a safe fallback and does not start a second X server.
- `.xinitrc` keeps `openbox-session` as the main X client.
- Openbox starts Calamares as a background application, so closing Calamares does not close X.
- Calamares can be launched again from the live desktop without restarting the login session.

This fixes the configuration-level root cause. A complete BIOS/UEFI and installed-system runtime test still needs to be run in a VM; the earlier audit could not perform that test because QEMU/OVMF were not available in the environment.

### Network and dependency cleanup

The live image previously mixed `systemd-networkd`, iwd, and NetworkManager. Calamares and the installation flow now use a single stack:

- NetworkManager for live and installed-system network management
- `wpa_supplicant` for wireless support
- `systemd-resolved` integration through `systemd-resolvconf`
- NetworkManager enabled in the installed target by Calamares

The profile also removes duplicate or unavailable package entries, avoids relying on AUR-only packages in the base image, includes `pciutils` for hardware detection, and removes stale branding references to assets that were not present.

Calamares is handled explicitly because it was not available in the active official Arch package set during the build work. The repository contains both a source PKGBUILD and a binary-repackaging PKGBUILD. The build script creates a temporary local pacman repository and injects the selected Calamares package into the ISO without committing generated packages.

### Build reliability fixes

The first large build attempt hit a per-mount quota while writing the SquashFS image under `/tmp`, even though the host reported free space. Moving the mkarchiso working directory and output to a filesystem without that quota allowed the ISO build to complete. The build script therefore exposes `SATROS_BUILD_ROOT` and `SATROS_OUTPUT_DIR`, so large builds do not need to use a constrained temporary mount.

## Reconstructing the ISO

Linux, macOS, and WSL:

```bash
cat satros-2026.09.12-x86_64.iso.part-aa \
    satros-2026.09.12-x86_64.iso.part-ab \
    > satros-2026.09.12-x86_64.iso
```

Verify the downloaded parts and the reconstructed image:

```bash
sha256sum -c SHA256SUMS
sha256sum satros-2026.09.12-x86_64.iso
```

On Windows PowerShell, use:

```powershell
Get-Content .\SHA256SUMS
cmd /c copy /b satros-2026.09.12-x86_64.iso.part-aa+satros-2026.09.12-x86_64.iso.part-ab satros-2026.09.12-x86_64.iso
Get-FileHash .\satros-2026.09.12-x86_64.iso -Algorithm SHA256
```

The SHA-256 values in `SHA256SUMS` are authoritative. Do not boot or install an image whose checksum does not match.

For the v0.03 image reconstructed from the release parts, the expected ISO SHA-256 is:

```text
71fccf86ac894d03689bbc5928520c7b678cf1039d0804260f2373feb9a8217f
```

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

## Calamares installation flow

The current workflow is intentionally split into a user-facing phase and an execution phase:

| Phase | Steps | Purpose |
| --- | --- | --- |
| Selection | Welcome, locale, keyboard, package chooser, partitioning, users, network, summary | Collect choices and show the final plan before disk changes |
| Installation | Partition, mount, unpack live filesystem, machine ID, `fstab`, locale, keyboard, local configuration, network, clock, services | Create the target system and copy the base satrOS filesystem |
| Packages | Pacman package database, selected package groups, optional netinstall packages | Install the selected kernel, desktop, drivers, and applications |
| Finalization | Hardware report, `mkinitcpio`, GRUB configuration, bootloader, unmount | Make the installed system bootable and ready for the first restart |
| Completion | Finished page | Report the result and allow the user to reboot |

The package chooser currently exposes these groups:

- **Kernel:** standard Linux, Linux LTS, or Linux Zen
- **Desktop:** KDE Plasma, GNOME, Hyprland, plain i3wm, or i3wm with Polybar and Rofi
- **Browser:** Firefox or Chromium
- **Graphics:** NVIDIA open driver and utilities
- **Applications:** Steam, htop, GIMP, LibreOffice, Discord, Telegram Desktop, and VLC

Package availability is still determined by the configured pacman repositories and the state of their mirrors. If an optional package is not available in the enabled repositories, the installation can fail at the package step even though the live system itself booted correctly.

## What was checked before publishing v0.03

The build and static audit covered the following items:

- ISO generation completed successfully with `mkarchiso`.
- ISO metadata and the hybrid boot layout were inspected.
- BIOS/Syslinux and UEFI/systemd-boot entries are present in the image structure.
- Calamares, its branding, local module configuration, and the package chooser are present.
- NetworkManager configuration is present and enabled for the installed system.
- CPU/GPU helper scripts are included with executable permissions.
- The bootloop-causing `exec startx` pattern is absent from the current startup path.
- The initramfs helper and Calamares configuration use Arch's `mkinitcpio`, not Debian's `update-initramfs`.
- Bash syntax, duplicate package entries, file permissions, and `git diff --check` were checked during the audit.

The following still require a real VM test and should not be treated as universally proven by the static audit alone: BIOS boot, UEFI boot, Xorg startup, Openbox startup, closing and reopening Calamares, full installation to a virtual disk, first boot from the installed disk, and reboot after installation.

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
SATROS_BUILD_ROOT=/path/to/build \
SATROS_OUTPUT_DIR=/path/to/output \
./build-iso.sh
```

The build uses the current Arch repositories and mirrors, so the exact package versions and resulting image contents can change over time. For reproducible builds, pin the package repositories and record the build date, package database state, and checksums.

### Build outputs and validation

The final ISO name contains the satrOS date version, for example `satros-2026.09.12-x86_64.iso`. Before publishing a build, validate at least the following:

```bash
# Confirm the image exists and record its size.
ls -lh /path/to/output/*.iso

# Record the release checksum.
sha256sum /path/to/output/satros-YYYY.MM.DD-x86_64.iso
```

Then boot the image in a virtual machine once in BIOS mode and once in UEFI mode. In the live session, check that Openbox starts, the Calamares launcher is available, the network can be configured, and the package chooser opens. For an installer test, use a disposable virtual disk and verify that the first installed boot reaches the installed system rather than the live media.

For a release larger than GitHub's per-asset limit, split the verified ISO only after the final checksum has been calculated:

```bash
split -b 1800M satros-YYYY.MM.DD-x86_64.iso satros-YYYY.MM.DD-x86_64.iso.part-
sha256sum satros-YYYY.MM.DD-x86_64.iso.part-* > SHA256SUMS
```

Keep the original ISO checksum in the release checksum file as well. Users should verify the parts before using them and verify the reconstructed image before writing it to USB.

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

## Troubleshooting

### The installer cannot download packages

Check that the live session has a working network connection and that the selected mirror is reachable. The package and netinstall steps use pacman repositories, so a temporary mirror or DNS failure can stop installation even when the image booted normally. Retry after fixing the connection rather than repeatedly repartitioning the target disk.

### A selected desktop or application is unavailable

The package chooser is declarative: it passes the selected package names to pacman. Package names and repository availability can change over time. Inspect the Calamares log, confirm the package exists in the enabled repositories, and rebuild the profile if the package has been renamed or moved.

### The installed system does not boot after a kernel change

Boot the live image again, mount the installed system, and inspect the initramfs and bootloader configuration. The normal installer path runs `satros-generate-initramfs` after package installation; that helper discovers every installed `/usr/lib/modules/*/vmlinuz` image and calls `mkinitcpio` for each one. A missing kernel package or an interrupted package transaction must be repaired before regenerating the initramfs.

### The live image shows the wrong graphics result

The GPU helper is informational and depends on `pciutils`/`lspci` and the hardware being visible to the live session. It deliberately does not install drivers automatically. Use the package chooser to select the appropriate supported driver, or use the standard kernel fallback when testing in a virtual machine.

### The ISO checksum does not match

Do not write the image to USB. Re-download the part whose checksum fails, verify that the two parts were concatenated in `aa` then `ab` order, and run `sha256sum -c SHA256SUMS` again.

## Safety and support boundaries

- Partitioning, bootloader installation, and writing an ISO to a block device can destroy data.
- Always back up important files and use a disposable virtual disk for installer development.
- The image currently targets `x86_64` hardware.
- Hardware compatibility is not guaranteed for every GPU, laptop firmware, storage controller, or virtual machine.
- The build follows current Arch repositories, so package versions, mirrors, and optional package availability are not fixed by this repository alone.
- The project is not a replacement for a tested backup or recovery plan.

## Development notes

- Keep generated output outside tracked source directories.
- Test both BIOS and UEFI boot paths after changing boot configuration.
- Test the Calamares flow in a virtual machine before installing on physical hardware.
- Verify that the installed system can regenerate its initramfs after kernel changes.
- Recalculate and publish SHA-256 checksums for every release image.
- Treat disk partitioning and raw USB writing as destructive operations.

## Project status

satrOS is an active development project. v0.03 establishes the current installable Calamares flow and release process, but hardware compatibility, package versions, installer behavior, and visual design may change between builds. Always back up important data before testing the installer.

## License and attribution

The repository contains project-specific configuration and scripts assembled around Arch Linux and archiso. Check individual files for their applicable license headers and upstream attribution. Arch Linux trademarks and project materials remain the property of their respective owners.
