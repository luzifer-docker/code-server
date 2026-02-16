FROM ghcr.io/luzifer-docker/archlinux:latest@sha256:2ceaa073035bdc4f09ee23296dea8e819bfd31c92c4e81540fa2f243bb4c335b AS builder

ENV GOPATH=/go \
    CGO_ENABLED=0

RUN set -ex \
 && pacman -Sy --noconfirm \
      go \
 && go install github.com/boxboat/fixuid@v0.6.0


FROM ghcr.io/luzifer-docker/archlinux:latest@sha256:2ceaa073035bdc4f09ee23296dea8e819bfd31c92c4e81540fa2f243bb4c335b

ARG CODE_SERVER_VERSION=4.109.2
ARG DUMB_INIT_VERSION=1.2.5

COPY --from=builder /go/bin/fixuid  /usr/local/bin/fixuid

COPY build.sh /usr/local/bin/build.sh
RUN set -ex \
 && bash /usr/local/bin/build.sh

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

EXPOSE 8080

# This way, if someone sets $DOCKER_USER, docker-exec will still work as
# the uid will remain the same. note: only relevant if -u isn't passed to
# docker-run.
USER 1000
ENV USER=coder
WORKDIR /home/coder

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--auth", "none", "--bind-addr", "0.0.0.0:8080", "--session-socket", "/tmp/code-server-ipc.sock", "."]
