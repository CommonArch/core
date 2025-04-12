FROM docker.io/library/archlinux:base-devel AS pacstrap

ARG ARCHIVE_DATE=2025/04/17
ARG ARCHIVE_SERVER=https://archive.archlinux.org/repos

RUN pacman-key --init
RUN pacman -Sy --needed --noconfirm archlinux-keyring arch-install-scripts

WORKDIR /

COPY pacstrap-docker /usr/bin
RUN <<EOF cat > /etc/pacman.conf
[options]
Architecture = auto
ParallelDownloads = 6
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Never

[core]
Server = $ARCHIVE_SERVER/$ARCHIVE_DATE/core/os/\$arch

[extra]
Server = $ARCHIVE_SERVER/$ARCHIVE_DATE/extra/os/\$arch
EOF

#RUN sed -i "s|ARCHIVE_SERVER|$ARCHIVE_SERVER|g" /etc/pacman.conf
#RUN sed -i "s|ARCHIVE_DATE|$ARCHIVE_DATE|g" /etc/pacman.conf
RUN cat /etc/pacman.conf

RUN rm -rf /rootfs; mkdir /rootfs
RUN pacstrap-docker /rootfs base

FROM scratch as root

COPY --from=pacstrap /rootfs/ /

LABEL supports-commonarch="true" \
      name="CommonArch Base Image" \
      usage="This image is meant to be used on CommonArch" \
      summary="Base image for creating CommonArch Desktop images" \
      maintainer="Rudra Saraswat <rswat09@gmail.com>"

# Install extra packages
COPY extra-packages /
RUN pacman -Syu --needed --noconfirm - < extra-packages
RUN rm /extra-packages

# Install and enable networkmanager and bluez
RUN pacman -Syu --needed --noconfirm networkmanager bluez
RUN systemctl enable NetworkManager; systemctl enable bluetooth

# Clean up cache
RUN yes | pacman -Scc

# Enable sudo permission for wheel users
RUN echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel
