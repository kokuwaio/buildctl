# ignore pipefail because
# bash is non-default location https://github.com/tianon/docker-bash/issues/29
# hadolint only uses default locations https://github.com/hadolint/hadolint/issues/977
# hadolint global ignore=DL4006

FROM docker.io/library/bash:5.3.3@sha256:ae4668c2560999e65e89532cd2ad1b6688bb23298189f0bd229ef80fa4bd0831
SHELL ["/usr/local/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]

# workaround until we have a env `CI_COMMIT_TIMESTAMP`
# see https://github.com/woodpecker-ci/woodpecker/issues/5245
RUN apk add git~=2 --no-cache

ARG TARGETARCH
RUN wget -q "https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-$TARGETARCH" --output-document=/usr/local/bin/jq && \
	chmod 555 /usr/local/bin/jq

RUN wget -q "https://github.com/moby/buildkit/releases/download/v0.23.2/buildkit-v0.23.2.linux-$TARGETARCH.tar.gz" --output-document=- | \
	tar --gz --extract --directory=/usr/local bin/buildctl && \
	chmod 555 /usr/local/bin/buildctl

COPY --chmod=555 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

RUN mkdir -p /home/buildkit/.docker/ && echo '{}' > /home/buildkit/.docker/config.json && chown 1000:1000 /home/buildkit -R
ENV HOME=/home/buildkit
USER 1000:1000
