FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential flex bison libssl-dev libelf-dev libncurses-dev python3 \
    autoconf libudev-dev libtool bc git ca-certificates curl jq pkg-config \
    dwarves rsync kmod cpio \
    && rm -rf /var/lib/apt/lists/*

# Install ccache for faster builds
RUN apt-get update && apt-get install -y ccache
ENV PATH="/usr/lib/ccache:$PATH"

WORKDIR /workspace

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]