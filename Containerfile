# SPDX-FileCopyrightText: © 2026 Nfrastack <code@nfrastack.com>
#
# SPDX-License-Identifier: MIT

ARG \
    BASE_IMAGE

FROM ${BASE_IMAGE}

LABEL \
        org.opencontainers.image.title="ARR" \
        org.opencontainers.image.description="ARR" \
        org.opencontainers.image.url="https://hub.docker.com/r/nfrastack/arr" \
        org.opencontainers.image.documentation="https://github.com/nfrastack/container-arr/blob/main/README.md" \
        org.opencontainers.image.source="https://github.com/nfrastack/container-arr.git" \
        org.opencontainers.image.authors="Nfrastack <code@nfrastack.com>" \
        org.opencontainers.image.vendor="Nfrastack <https://www.nfrastack.com>" \
        org.opencontainers.image.licenses="MIT"

COPY CHANGELOG.md /usr/src/container/CHANGELOG.md
COPY LICENSE /usr/src/container/LICENSE
COPY README.md /usr/src/container/README.md

ARG \
    SONARR_VERSION="v4.0.19.2979" \
    SONARR_BRANCH="main" \
    SONARR_REPO_URL="https://github.com/Sonarr/Sonarr" \
    RADARR_VERSION="v6.2.1.10461" \
    RADARR_BRANCH="master" \
    RADARR_REPO_URL="https://github.com/Radarr/Radarr" \
    PROWLARR_VERSION="v2.4.0.5397" \
    PROWLARR_BRANCH="master" \
    PROWLARR_REPO_URL="https://github.com/Prowlarr/Prowlarr" \
    QBITTORRENT_VERSION="release-5.2.1" \
    QBITTORRENT_REPO_URL="https://github.com/qbittorrent/qBittorrent"

ENV \
    IMAGE_NAME="nfrastack/arr" \
    IMAGE_REPO_URL="https://github.com/nfrastack/container-arr/"

RUN echo "" && \
    BUILD_ENV=" \
              " && \
    SHARED_BUILD_DEPS_ALPINE=" \
                            build-base \
                            git \
                         " \
                         && \
    SHARED_RUN_DEPS_ALPINE=" \
                        " \
                        && \
    ARR_BUILD_DEPS_ALPINE=" \
                          " && \
    ARR_RUN_DEPS_ALPINE=" \
                            icu \
                            sqlite-libs \
                            xmlstarlet \
                          " \
                          && \
    QBITTORRENT_BUILD_DEPS_ALPINE=" \
                                    boost-dev \
                                    cmake \
                                    libtorrent-rasterbar-dev \
                                    openssl-dev \
                                    python3 \
                                    qt6-qtbase-dev \
                                    qt6-qtbase-private-dev \
                                    qt6-qttools-dev \
                                    zlib-dev \
                                  " \
                                  && \
    QBITTORRENT_RUN_DEPS_ALPINE=" \
                                    boost \
                                    libtorrent-rasterbar \
                                    qt6-qtbase \
                                    qt6-qttools \
                                    python3 \
                                    zlib \
                                " \
                                && \
    \
    source /container/base/functions/container/build && \
    container_build_log image && \
    create_user arr 1000 arr 1000 /dev/null && \
    package update && \
    package upgrade && \
    package install \
                        ARR_BUILD_DEPS \
                        ARR_RUN_DEPS \
                        QBITTORRENT_BUILD_DEPS \
                        QBITTORRENT_RUN_DEPS \
                        SHARED_BUILD_DEPS \
                        SHARED_RUN_DEPS \
                    && \
    \
    create_user qbittorrent 1001 qbittorrent 1001 /dev/null && \
    add_user_group arr qbittorrent && \
    clone_git_repo "${QBITTORRENT_REPO_URL}" "${QBITTORRENT_VERSION}" && \
    cmake -B build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DGUI=OFF \
        && \
    cmake --build build -j $(nproc --ignore=1) && \
    cmake --install build && \
    container_build_log add "qBittorrent" "${QBITTORRENT_VERSION}" "${QBITTORRENT_REPO_URL}" && \
    \
    create_user sonarr 1002 sonarr 1002 /dev/null && \
    add_user_group arr sonarr && \
    case $(container_info arch) in \
        x86_64)  _sonarr_arch="x64" ;; \
        aarch64) _sonarr_arch="arm64" ;; \
        *) echo "Unsupported architecture for Sonarr" ; exit 1 ;; \
    esac && \
    case $(container_info distro) in \
        alpine) _sonarr_platform="linux-musl-${_sonarr_arch}" ;; \
        *)      _sonarr_platform="linux-${_sonarr_arch}" ;; \
    esac && \
    mkdir -p /opt/sonarr && \
    curl -sSL "https://github.com/Sonarr/Sonarr/releases/download/${SONARR_VERSION}/Sonarr.${SONARR_BRANCH}.${SONARR_VERSION#v}.${_sonarr_platform}.tar.gz" | tar xzfa - --strip=1 -C /opt/sonarr && \
    chown -R sonarr:arr /opt/sonarr && \
    container_build_log add "Sonarr" "${SONARR_VERSION}" "${SONARR_REPO_URL}" && \
    \
    create_user radarr 1003 radarr 1003 /dev/null && \
    add_user_group arr radarr && \
    case $(container_info arch) in \
        x86_64)  _radarr_arch="x64" ;; \
        aarch64) _radarr_arch="arm64" ;; \
        *) echo "Unsupported architecture for Radarr" ; exit 1 ;; \
    esac && \
    case $(container_info distro) in \
        alpine) _radarr_platform="linux-musl-core-${_radarr_arch}" ;; \
        *)      _radarr_platform="linux-core-${_radarr_arch}" ;; \
    esac && \
    mkdir -p /opt/radarr && \
    curl -sSL "https://github.com/Radarr/Radarr/releases/download/${RADARR_VERSION}/Radarr.${RADARR_BRANCH}.${RADARR_VERSION#v}.${_radarr_platform}.tar.gz" | tar xzfa - --strip=1 -C /opt/radarr && \
    chown -R radarr:arr /opt/radarr && \
    container_build_log add "Radarr" "${RADARR_VERSION}" "${RADARR_REPO_URL}" && \
    \
    source /container/base/functions/container/build && \
    create_user prowlarr 1004 prowlarr 1004 /dev/null && \
    add_user_group arr prowlarr && \
    case $(container_info arch) in \
        x86_64)  _prowlarr_arch="x64" ;; \
        aarch64) _prowlarr_arch="arm64" ;; \
        *) echo "Unsupported architecture for Prowlarr" ; exit 1 ;; \
    esac && \
    case $(container_info distro) in \
        alpine) _prowlarr_platform="linux-musl-core-${_prowlarr_arch}" ;; \
        *)      _prowlarr_platform="linux-core-${_prowlarr_arch}" ;; \
    esac && \
    mkdir -p /opt/prowlarr && \
    curl -sSL "https://github.com/Prowlarr/Prowlarr/releases/download/${PROWLARR_VERSION}/Prowlarr.${PROWLARR_BRANCH}.${PROWLARR_VERSION#v}.${_prowlarr_platform}.tar.gz" | tar xzfa - --strip=1 -C /opt/prowlarr && \
    chown -R prowlarr:arr /opt/prowlarr && \
    container_build_log add "Prowlarr" "${PROWLARR_VERSION}" "${PROWLARR_REPO_URL}" && \
    \
    package remove \
                        ARR_BUILD_DEPS \
                        QBITTORRENT_BUILD_DEPS \
                        SHARED_BUILD_DEPS \
                    && \
    package cleanup

COPY rootfs /
