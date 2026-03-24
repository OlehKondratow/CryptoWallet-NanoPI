FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chrpath \
    cpio \
    curl \
    debianutils \
    diffstat \
    file \
    gawk \
    gcc \
    git \
    iputils-ping \
    locales \
    lz4 \
    make \
    python3 \
    python3-pexpect \
    python3-pip \
    python3-venv \
    rsync \
    socat \
    sudo \
    texinfo \
    unzip \
    wget \
    xz-utils \
    zstd \
 && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install kas as recommended modern Yocto frontend.
RUN pip3 install --no-cache-dir kas

RUN useradd -m -u 1000 -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder

WORKDIR /work

COPY entrypoint.sh /usr/local/bin/infra-entrypoint.sh
RUN chmod +x /usr/local/bin/infra-entrypoint.sh

USER builder

ENTRYPOINT ["/usr/local/bin/infra-entrypoint.sh"]
CMD ["bash"]
