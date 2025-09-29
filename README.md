# Buildctl WoodpeckerCI Plugin

[![pulls](https://img.shields.io/docker/pulls/kokuwaio/buildctl)](https://hub.docker.com/r/kokuwaio/buildctl)
[![size](https://img.shields.io/docker/image-size/kokuwaio/buildctl)](https://hub.docker.com/r/kokuwaio/buildctl)
[![dockerfile](https://img.shields.io/badge/source-Dockerfile%20-blue)](https://git.kokuwa.io/woodpecker/buildctl/src/branch/main/Dockerfile)
[![license](https://img.shields.io/badge/License-EUPL%201.2-blue)](https://git.kokuwa.io/woodpecker/buildctl/src/branch/main/LICENSE)
[![prs](https://img.shields.io/gitea/pull-requests/open/woodpecker/buildctl?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/woodpecker/buildctl/pulls)
[![issues](https://img.shields.io/gitea/issues/open/woodpecker/buildctl?gitea_url=https%3A%2F%2Fgit.kokuwa.io)](https://git.kokuwa.io/woodpecker/buildctl/issues)

A [WoodpeckerCI](https://woodpecker-ci.org) plugin for [buildctl](https://github.com/moby/buildkit) to build container images using a remote buildkit host.  
Also usable with Gitlab, Github or locally, see examples for usage.

## Features

- preconfigured for [reproducible builds](https://github.com/moby/buildkit/blob/master/docs/build-repro.md)
- attestations not yet supported because of [github.com/moby/buildkit/issues/3552](https://github.com/moby/buildkit/issues/3552)
- runnable with local buildkit daemon

## Example

WoodpeckerCI:

```yaml
steps:
  buildctl:
    depends_on: []
    image: kokuwaio/buildctl:v0.24.0
    settings:
      name:
        - registry.example.org/foo:latest
        - registry.example.org/foo:0.0.1
      annotation:
        org.opencontainers.image.title: My Image
        org.opencontainers.image.description: A description.
      build-args:
        NPM_CONFIG_REGISTRY: ${NPM_CONFIG_REGISTRY} # reused from ci env
        FOO: bar
      platform: [linux/amd64, linux/arm64]
      auth:
        registry.example.org:
          username: {from_secret: my_username}
          password: {from_secret: my_password}
        https://index.docker.io/v1/":
          username: {from_secret: docker_io_username}
          password: {from_secret: docker_io_password}
```

Gitlab: (using script is needed because of <https://gitlab.com/gitlab-org/gitlab/-/issues/19717>)

```yaml
buildctl:
  needs: []
  stage: lint
  image:
    name: kokuwaio/buildctbuildctl:v0.24.0
    entrypoint: [""]
  script: [/usr/local/bin/entrypoint.sh]
  variables:
    PLUGIN_ADDR: tcp://0.8.1.5:1234
    PLUGIN_NAME: registry.example.org/foo:latest,registry.example.org/foo:0.0.1
    PLUGIN_PLATFORM: linux/amd64,linux/arm64
    PLUGIN_AUTH: '{"registry.example.org":{"username":"my-user","password":"changeMe"}}'
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

CLI (will reuse docker credentials of current user):

```bash
PLUGIN_ADDR=tcp://0.8.1.5:1234
PLUGIN_NAME=registry.example.org/foo:latest,registry.example.org/foo:0.0.1
PLUGIN_PLATFORM=linux/amd64,linux/arm64
docker run --rm --user=$(id -u) --volume=$HOME:$HOME:ro --workdir=$PWD --env=PLUGIN_ADDR --env=PLUGIN_NAME --env=PLUGIN_PLATFORM kokuwaio/buildctl
```

## Settings

| Settings Name       | Environment              | Default                     | Description                                        |
| ------------------- | ------------------------ | --------------------------- | -------------------------------------------------- |
| `addr`              | PLUGIN_ADDR              | `$BUILDKIT_HOST`            | Buildkit host to use.                              |
| `frontend`          | PLUGIN_FRONTEND          | `dockerfile.v0`             | Only dockerfile frontend supported right now       |
| `context`           | PLUGIN_CONTEXT           | `$PWD`                      | Context directory to use for build                 |
| `dockerfile`        | PLUGIN_DOCKERFILE        | `Dockerfile`                | Dockerfile to use.                                 |
| `target`            | PLUGIN_TARGET            | `none`                      | Dockerfile target                                  |
| `build-args`        | PLUGIN_BUILD_ARGS        | `none`                      | Build args to pass to build                        |
| `platform`          | PLUGIN_PLATFORM          | `none`                      | Target platform for container image.               |
| `reproducible`      | PLUGIN_REPRODUCIBLE      | `true`                      | Build with reproducible settings.                 |
| `source-epoch-date` | PLUGIN_SOURCE_DATE_EPOCH | `git log -1 --format="%at"` | Timestamp to use for reproducible builds.         |
| `name`              | PLUGIN_NAME              | `none`                      | Images names where to push the image.              |
| `annotation`        | PLUGIN_ANNOTATION        | `none`                      | Annotations (also known as labels) to add to image |
| `push`              | PLUGIN_PUSH              | `true`                      | Push images if output names are set.               |
| `auth`              | PLUGIN_AUTH              | `none`                      | Auth for private registries                        |
| `env-file`          | PLUGIN_ENV_FILE          | `none`                      | Source environment values from given file          |

## Alternatives

| Image                                                           | Comment                           | amd64 | arm64 |
| --------------------------------------------------------------- | --------------------------------- |:-----:|:-----:|
| [kokuwaio/buildctl](https://hub.docker.com/r/kokuwaio/buildctl) | Woodpecker plugin                 | [![size](https://img.shields.io/docker/image-size/kokuwaio/buildctl?arch=amd64&label=)](https://hub.docker.com/r/kokuwaio/buildctl) | [![size](https://img.shields.io/docker/image-size/kokuwaio/buildctl?arch=arm64&label=)](https://hub.docker.com/r/kokuwaio/buildctl) |
| [moby/buildkit](https://hub.docker.com/r/moby/buildkit)         | not a Woodpecker plugin           | [![size](https://img.shields.io/docker/image-size/moby/buildkit?arch=amd64&label=)](https://hub.docker.com/r/moby/buildkit) | [![size](https://img.shields.io/docker/image-size/moby/buildkit?arch=arm64&label=)](https://hub.docker.com/r/moby/buildkit) |
| [nordseth/buildctl](https://hub.docker.com/r/nordseth/buildctl) | not a Woodpecker plugin           | [![size](https://img.shields.io/docker/image-size/nordseth/buildctl?arch=amd64&label=)](https://hub.docker.com/r/nordseth/buildctl) | [![size](https://img.shields.io/docker/image-size/nordseth/buildctl?arch=arm64&label=)](https://hub.docker.com/r/nordseth/buildctl) |
| [shopstic/buildctl](https://hub.docker.com/r/shopstic/buildctl) | not a Woodpecker plugin, outdated | [![size](https://img.shields.io/docker/image-size/shopstic/buildctl?arch=amd64&label=)](https://hub.docker.com/r/shopstic/buildctl) | [![size](https://img.shields.io/docker/image-size/shopstic/buildctl?arch=arm64&label=)](https://hub.docker.com/r/shopstic/buildctl) |
| [agisoft/buildctl](https://hub.docker.com/r/agisoft/buildctl)   | not a Woodpecker plugin, outdated | [![size](https://img.shields.io/docker/image-size/agisoft/buildctl?arch=amd64&label=)](https://hub.docker.com/r/agisoft/buildctl) | [![size](https://img.shields.io/docker/image-size/agisoft/buildctl?arch=arm64&label=)](https://hub.docker.com/r/agisoft/buildctl) |
