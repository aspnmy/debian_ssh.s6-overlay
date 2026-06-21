ARG GO_VERSION=1.12.4

# 使用 --platform 拉取目标架构的 golang 镜像
FROM --platform=$TARGETPLATFORM golang:${GO_VERSION}-alpine AS builder

# 由 buildx 自动注入的目标平台参数
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# 保留作为构建时的覆盖参数（与原有兼容）
ARG GOOS
ARG GOARCH

COPY . /go/src/github.com/docker/swarm
WORKDIR /go/src/github.com/docker/swarm

RUN set -ex \
    && apk add --no-cache --virtual .build-deps git \
    && GOARCH=${TARGETARCH:-$GOARCH} GOOS=${TARGETOS:-$GOOS} CGO_ENABLED=0 \
       go install -v -a -tags netgo -installsuffix netgo \
       -ldflags "-w -X github.com/docker/swarm/version.GITCOMMIT=$(git rev-parse --short HEAD) -X github.com/docker/swarm/version.BUILDTIME=$(date -u +%FT%T%z)" \
    && apk del .build-deps

ENV SWARM_HOST :2375
EXPOSE 2375

# 注意：$HOME 是运行时环境变量，在 Dockerfile 中可能为空，建议指定绝对路径
VOLUME /root/.swarm

ENTRYPOINT ["swarm"]
CMD ["--help"]