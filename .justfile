# https://just.systems/man/en/

[private]
@default:
    just --list --unsorted

# Run linter.
@lint:
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/just:1.45.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/shellcheck:v0.11.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/hadolint:v2.14.0
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/yamllint:v1.37.1
    docker run --rm --read-only --volume=$PWD:$PWD:rw --workdir=$PWD kokuwaio/markdownlint:0.47.0 --fix
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD kokuwaio/renovate-config-validator:42
    docker run --rm --read-only --volume=$PWD:$PWD:ro --workdir=$PWD woodpeckerci/woodpecker-cli lint

# Build image with local docker daemon.
@build:
    docker buildx build . --platform=linux/amd64,linux/arm64

# Inspect image layers with `dive`.
@dive:
    dive build .

# Test created image.
@test:
    docker build . --tag=kokuwaio/buildctl:dev
    docker run --rm --volume=$PWD:$PWD:ro --workdir=$PWD --env=CI_WORKSPACE=$PWD --env=BUILDKIT_HOST kokuwaio/buildctl:dev
