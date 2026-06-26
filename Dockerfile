# hadolint shell=/usr/local/bin/bash
# hadolint global ignore=DL4006

FROM docker.io/library/bash:5.3.15@sha256:a19c811ee9e97fa8a080001d82b8e0ded303f0795cffdb1cbd162731bc8ce208
SHELL ["/usr/local/bin/bash", "-u", "-e", "-o", "pipefail", "-c"]
ARG TARGETARCH

RUN wget --quiet \
        "https://github.com/jqlang/jq/releases/download/jq-1.8.1/jq-linux-$TARGETARCH" \
        "https://github.com/jqlang/jq/releases/download/jq-1.8.1/sha256sum.txt" && \
    grep "jq-linux-$TARGETARCH" sha256sum.txt | sha256sum -csw && rm sha256sum.txt && \
    mv "jq-linux-$TARGETARCH" /usr/local/bin/jq && chmod 555 /usr/local/bin/jq

RUN wget -q "https://github.com/moby/buildkit/releases/download/v0.31.1/buildkit-v0.31.1.linux-$TARGETARCH.tar.gz" --output-document=- | \
	tar --gz --extract --directory=/usr/local bin/buildctl && \
	chmod 555 /usr/local/bin/buildctl

COPY --chmod=555 entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

RUN mkdir -p /home/buildkit/.docker/ && echo '{}' > /home/buildkit/.docker/config.json && chown 1000:1000 /home/buildkit -R
ENV HOME=/home/buildkit
USER 1000:1000
