# =============================================================================
# Stage 1: Build FEX-Emu
# =============================================================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV CMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake/Qt5

RUN apt-get update && apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    libsdl2-dev \
    libepoxy-dev \
    libssl-dev \
    python-setuptools \
    g++-x86-64-linux-gnu \
    nasm \
    python3-clang \
    libstdc++-10-dev-i386-cross \
    libstdc++-10-dev-amd64-cross \
    libstdc++-10-dev-arm64-cross \
    squashfs-tools \
    squashfuse \
    qtbase5-dev \
    qtchooser \
    qt5-qmake \
    qtbase5-dev-tools \
    qtdeclarative5-dev \
    qml-module-qtquick2 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone --recurse-submodules https://github.com/FEX-Emu/FEX.git && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DUSE_LINKER=lld \
        -DENABLE_LTO=True \
        -DBUILD_TESTS=False \
        -DENABLE_ASSERTIONS=False \
        -G Ninja .. && \
    ninja && \
    DESTDIR=/fex-install ninja install

# =============================================================================
# Stage 2: Runtime
# =============================================================================
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install only runtime dependencies
RUN apt-get update && apt-get install -y \
    libsdl2-2.0-0 \
    libepoxy0 \
    libssl3 \
    squashfuse \
    squashfs-tools \
    fuse \
    curl \
    ca-certificates \
    binfmt-support \
    && rm -rf /var/lib/apt/lists/*

# Copy FEX binaries from builder
COPY --from=builder /fex-install/usr /usr

# Create steam user with UID 1001 to match host user for volume permissions
RUN useradd -m -s /bin/bash -u 1001 steam && \
    mkdir -p /home/steam/.local/share/7DaysToDie/Saves && \
    mkdir -p /home/steam/Steam/servers/7DaysToDie && \
    mkdir -p /home/steam/.fex-emu && \
    chown -R steam:steam /home/steam

USER steam
WORKDIR /home/steam

# Note: FEX RootFS and SteamCMD/7DTD will be installed at first run
# This avoids needing FUSE during build

ENTRYPOINT ["/home/steam/start_7dtd_server.sh"]
