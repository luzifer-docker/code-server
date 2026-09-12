FROM docker.io/library/golang:1.27.1@sha256:512690a5660563b57d37ecc31129e7f136e831db2aed24a1dbeb8ad7380dc0fa AS builder

ENV GOPATH=/go \
    CGO_ENABLED=0

ARG CODE_SERVER_VERSION=4.136.2
ARG DUMB_INIT_VERSION=1.2.5

SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]

RUN mkdir /rootfs/

# Install dumb-init into rootfs
RUN <<-EOF
  curl -sSfL "https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64" |
    install -Dm0755 /dev/stdin /rootfs/usr/bin/dumb-init
EOF

# Install fixuid into rootfs
RUN <<-EOF
  go install github.com/boxboat/fixuid@v0.6.0
  install -Dm4755 /go/bin/fixuid /rootfs/usr/local/bin/fixuid

  echo -e "user: coder\ngroup: coder" |
    install -Dm0644 /dev/stdin /rootfs/etc/fixuid/config.yml
EOF

# Install Code-Server Release
RUN <<-EOF
  install -dm0755 /rootfs/opt/code-server
  curl -sSfL "https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server-${CODE_SERVER_VERSION}-linux-amd64.tar.gz" |
    tar -xz -C /rootfs/opt/code-server --strip-components=1
EOF

COPY entrypoint.sh /rootfs/usr/local/bin/entrypoint.sh

# ---

FROM docker.io/library/debian:13.6-slim@sha256:d7e12182ce18b85b93007c1dedf31f2d29e01ccf3182cc4017c709b6259bc132

RUN <<-EOF
  set -ex

  # Install base packages
  apt-get update
  apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    curl \
    git \
    sudo
  apt-get autoremove --assume-yes --purge
  apt-get clean --assume-yes

  # Configure user to use
  useradd -m -u 1000 -U coder -s /bin/bash
  echo "coder ALL=(ALL) NOPASSWD:ALL" |
    install -Dm0640 /dev/stdin /etc/sudoers.d/nopasswd
EOF

COPY --from=builder /rootfs/ /

EXPOSE 8080

# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--auth", "none", "--bind-addr", "0.0.0.0:8080", "--session-socket", "/tmp/code-server-ipc.sock", "."]
