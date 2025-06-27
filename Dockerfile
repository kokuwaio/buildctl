# ignore pipefail because
# bash is non-default location https://github.com/tianon/docker-bash/issues/29
# hadolint only uses default locations https://github.com/hadolint/hadolint/issues/977
# hadolint global ignore=DL4006

FROM docker.io/library/bash:5.2.37@sha256:01a15c6f48f6a3c08431cd77e11567823530b18159889dca3b7309b707beef91
SHELL ["/usr/local/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]

# workaround until we have a env `CI_COMMIT_TIMESTAMP`
# see https://github.com/woodpecker-ci/woodpecker/issues/5245
RUN apk add git~=2 --no-cache

RUN ARCH=$(uname -m) && \
	[[ $ARCH == x86_64 ]] && export SUFFIX=amd64; \
	[[ $ARCH == aarch64 ]] && export SUFFIX=arm64; \
	[[ -z ${SUFFIX:-} ]] && echo "Unknown arch: $ARCH" && exit 1; \
	wget -q "https://github.com/jqlang/jq/releases/download/jq-1.8.0/jq-linux-$SUFFIX" --output-document=/usr/local/bin/jq && \
	chmod 555 /usr/local/bin/jq

RUN ARCH=$(uname -m) && \
	[[ $ARCH == x86_64 ]] && export SUFFIX=amd64; \
	[[ $ARCH == aarch64 ]] && export SUFFIX=arm64; \
	[[ -z ${SUFFIX:-} ]] && echo "Unknown arch: $ARCH" && exit 1; \
	wget -q "https://github.com/moby/buildkit/releases/download/v0.23.1/buildkit-v0.23.1.linux-$SUFFIX.tar.gz" --output-document=- | tar --gz --extract --directory=/usr/local bin/buildctl && \
	chmod 555 /usr/local/bin/buildctl

COPY --chmod=555 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

RUN mkdir -p /home/buildkit/.docker/ && echo '{}' > /home/buildkit/.docker/config.json && chown 1000:1000 /home/buildkit -R
ENV HOME=/home/buildkit
USER 1000:1000
