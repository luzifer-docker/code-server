#!/bin/bash
set -euxo pipefail

build_packages=()
install_packages=(
	curl
	git
	go
	openssh
	node
	npm
	sudo
	tar
)

pacman -Sy --noconfirm "${build_packages[@]}" "${install_packages[@]}"

# Install code-server release
curl -sSfL "https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" |
	tar -xz -C /opt
mv /opt/code-server-${CODE_SERVER_VERSION}-linux-amd64 /opt/code-server

# Install dumb-init
curl -sSfLo /usr/bin/dumb-init "https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64"
chmod 0755 /usr/bin/dumb-init

# Install and configure fixuid
curl -sSfL "https://github.com/boxboat/fixuid/releases/download/v${FIXUID_VERSION}/fixuid-${FIXUID_VERSION}-linux-amd64.tar.gz" |
	tar -xz -C /usr/local/bin
chown root:root /usr/local/bin/fixuid
chmod 4755 /usr/local/bin/fixuid

mkdir -p /etc/fixuid
echo "user: coder\ngroup: coder" >/etc/fixuid/config.yml

# Configure user to use
useradd -m -u 1000 -U coder
echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

[ ${#build_packages[@]} -gt 0 ] && pacman -Rs --noconfirm "${build_packages[@]}" || true
