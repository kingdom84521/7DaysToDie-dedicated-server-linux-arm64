FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV CMAKE_PREFIX_PATH=/usr/lib/x86_64-linux-gnu/cmake/Qt5

RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkg-config \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
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
    libc-bin \
    expect \
    curl \
    sudo \
    fuse \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools \
    qtdeclarative5-dev qml-module-qtquick2 \
    binfmt-support

RUN useradd -m -s /bin/bash fex && \
    usermod -aG sudo fex && \
    echo "fex ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/fex

USER fex

WORKDIR /home/fex


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
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install && \
    sudo update-binfmts --enable

RUN sudo useradd -m -s /bin/bash steam && \
    sudo apt-get update && \
    sudo apt-get install -y wget

USER root

RUN echo 'root:steamcmd' | chpasswd

USER steam

RUN FEXRootFSFetcher --distro-name=ubuntu --distro-version=22.04 --extract -y

WORKDIR /home/steam/Steam

RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - && \
    FEXBash -c './steamcmd.sh +force_install_dir "/home/steam/Steam/servers/7DaysToDie" +login anonymous +app_update 294420 -validate +quit'

USER root
