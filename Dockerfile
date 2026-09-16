# hadolint shell=/usr/local/bin/bash
# hadolint global ignore=DL4006

FROM docker.io/library/bash:5.3.20@sha256:17bcd6fab37baf523955fd74f1b443344456f7a0eec9deafb698db136f6f7aa0
SHELL ["/usr/local/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
ARG TARGETARCH

RUN wget --quiet \
        "https://github.com/jqlang/jq/releases/download/jq-1.8.2/jq-linux-$TARGETARCH" \
        "https://github.com/jqlang/jq/releases/download/jq-1.8.2/sha256sum.txt" && \
    grep "jq-linux-$TARGETARCH" sha256sum.txt | sha256sum -csw && rm sha256sum.txt && \
    mv "jq-linux-$TARGETARCH" /usr/local/bin/jq && chmod 555 /usr/local/bin/jq

RUN wget -q "https://github.com/moby/buildkit/releases/download/v0.33.0/buildkit-v0.33.0.linux-$TARGETARCH.tar.gz" --output-document=- | \
	tar --gz --extract --directory=/usr/local bin/buildctl && \
	chmod 555 /usr/local/bin/buildctl

COPY --chmod=555 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

RUN mkdir -p /home/buildkit/.docker/ && echo '{}' > /home/buildkit/.docker/config.json && chown 1000:1000 /home/buildkit -R
ENV HOME=/home/buildkit
USER 1000:1000
