FROM golang:1.27rc1-alpine3.24 AS builder

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT

# 保留用户自定义回退参数
ARG GOOS
ARG GOARCH

COPY . /go/src/github.com/docker/swarm
WORKDIR /go/src/github.com/docker/swarm

# 创建兼容的 go.mod 以适配 Go 1.27+（强制 modules）
RUN set -ex \
    && apk add --no-cache --virtual .build-deps git \
    && GITCOMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown") \
    && BUILDTIME=$(date -u +%FT%T%z) \
    && GOARCH="${TARGETARCH:-${GOARCH:-amd64}}" \
       GOOS="${TARGETOS:-${GOOS:-linux}}" \
       CGO_ENABLED=0 \
    # 创建兼容的 go.mod，声明模块路径
    && mkdir -p /go/src/github.com/docker/swarm \
    && cd /go/src/github.com/docker/swarm \
    && go mod init github.com/docker/swarm \
    # 注意：此项目需要一些 vendor/adapter 包，可能需 go mod tidy
    # 但为了最小可行构建，先尝试直接编译
    && go mod tidy -e 2>/dev/null || true \
    && go install -v -a -tags netgo -installsuffix netgo \
           -ldflags "-w -X github.com/docker/swarm/version.GITCOMMIT=${GITCOMMIT} -X github.com/docker/swarm/version.BUILDTIME=${BUILDTIME}" \
    && apk del .build-deps

ENV SWARM_HOST=:2375
EXPOSE 2375

VOLUME /root/.swarm

ENTRYPOINT ["swarm"]
CMD ["--help"]