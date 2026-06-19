# syntax=docker/dockerfile:1
# debian_ssh.s6-overlay — Multi-arch Dockerfile
# Build: docker buildx build --platform linux/amd64,linux/arm64 --build-arg BASEIMAGE=... --build-arg S6_VER=... .

ARG BASEIMAGE=debian:bookworm-slim
ARG S6_VER=3.2.3.0

FROM ${BASEIMAGE} AS s6-downloader
ARG S6_VER

# Pre-downloaded tarballs come from the CI workflow
COPY s6-downloads/ /tmp/s6-downloads/
RUN mkdir -p /tmp/s6 \
    && ln -sf /tmp/s6-downloads/s6-overlay-noarch.tar.xz /tmp/s6-noarch.tar.xz \
    && ARCH=$(uname -m | sed 's/aarch64/aarch64/;s/x86_64/x86_64/') \
    && ln -sf /tmp/s6-downloads/s6-overlay-${ARCH}.tar.xz /tmp/s6-arch.tar.xz \
    && tar -C /tmp/s6 -Jxpf /tmp/s6-noarch.tar.xz \
    && tar -C /tmp/s6 -Jxpf /tmp/s6-arch.tar.xz \
    && rm -f /tmp/s6-noarch.tar.xz /tmp/s6-arch.tar.xz

FROM ${BASEIMAGE}
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server netcat-openbsd python3 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY app/roottools/fix-warnings.sh /aspnmy/bin/
RUN bash /aspnmy/bin/fix-warnings.sh

COPY --from=s6-downloader /tmp/s6/ /

COPY app/roottools/setRootKey_Cli.sh.s6 /aspnmy/bin/
COPY app/roottools/mini-key-server.sh /aspnmy/bin/
RUN chmod +x /aspnmy/bin/setRootKey_Cli.sh.s6 \
    && chmod +x /aspnmy/bin/mini-key-server.sh

RUN rm -f /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/Shanghai" > /etc/timezone

RUN mkdir -p /root/.ssh /run/sshd /var/run/sshd /aspnmy/bin /aspnmy/wwwroot/ssh_key \
    && chmod 700 /root/.ssh /var/run/sshd \
    && chmod 755 /run/sshd

RUN bash /aspnmy/bin/setRootKey_Cli.sh.s6 superman

RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd/dependencies.d /etc/s6-overlay/s6-rc.d/sshd/log /var/log/sshd \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd \
    && touch /etc/s6-overlay/s6-rc.d/sshd/dependencies.d/base \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/sshd/type \
    && printf '#!/bin/sh\n/usr/sbin/sshd -D\n' > /etc/s6-overlay/s6-rc.d/sshd/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/sshd/run \
    && printf '#!/bin/sh\nexec s6-log -b -- n20 s1000000 /var/log/sshd\n' > /etc/s6-overlay/s6-rc.d/sshd/log/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/sshd/log/run

HEALTHCHECK --interval=30s --timeout=5s CMD pgrep sshd || exit 1
EXPOSE 25 8880 622
ENTRYPOINT ["/init"]
