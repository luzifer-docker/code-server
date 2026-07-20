# code-server

A small Docker image for running [code-server](https://github.com/coder/code-server). It is based on Debian and includes Git, curl, sudo, `fixuid`, and `dumb-init`.

The published image currently targets AMD64.

## Usage

```console
docker run --rm \
  -p 127.0.0.1:8080:8080 \
  -v "$PWD:/home/coder/project" \
  ghcr.io/luzifer-docker/code-server:latest \
  --auth none \
  --bind-addr 0.0.0.0:8080 \
  /home/coder/project
```

Open <http://localhost:8080> in a browser.

The default command already uses port `8080`, disables authentication, and opens `/home/coder`. Arguments supplied after the image name replace that command and are passed directly to code-server.

> [!WARNING]
> Authentication is disabled by default. Bind the port to localhost as shown above, place the container behind an authenticated reverse proxy, or start code-server with suitable authentication settings. Do not expose the default configuration directly to the internet.

## User and permissions

The container runs as `coder` with UID and GID `1000`. `fixuid` adjusts that account when the container is started with another numeric user and group:

```console
docker run --rm \
  --user "$(id -u):$(id -g)" \
  -p 127.0.0.1:8080:8080 \
  -v "$PWD:/home/coder/project" \
  ghcr.io/luzifer-docker/code-server:latest
```

Set `DOCKER_USER` to rename the in-container user while retaining `/home/coder` as its home directory.

## Building

```console
docker build --tag code-server .
```

The code-server and dumb-init versions can be overridden at build time:

```console
docker build \
  --build-arg CODE_SERVER_VERSION=4.129.0 \
  --build-arg DUMB_INIT_VERSION=1.2.5 \
  --tag code-server .
```

## License

This project is licensed under the [MIT License](LICENSE).
