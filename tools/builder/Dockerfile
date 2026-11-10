# Ambiente de build do E OS: Debian 13 (trixie) com live-build e QEMU.
# Os scripts eos.ps1 / eos.sh constroem esta imagem e rodam tudo dentro dela.
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      live-build debootstrap debian-archive-keyring \
      squashfs-tools xorriso mtools dosfstools \
      isolinux syslinux-common syslinux-utils \
      grub-pc-bin grub-efi-amd64-bin \
      ca-certificates cpio file zstd xz-utils \
      librsvg2-bin fonts-dejavu-core \
      qemu-system-x86 qemu-utils ovmf expect \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /work
