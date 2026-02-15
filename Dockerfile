FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    dpkg-dev \
    gnupg \
    gnupg-agent \
    apt-utils \
    curl \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo

# Create directory structure for apt repo
RUN mkdir -p /repo/pool /repo/dists

VOLUME ["/repo"]

CMD ["/bin/bash"]
