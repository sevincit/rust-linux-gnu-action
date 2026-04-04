FROM almalinux:10

ARG TOOLCHAIN

ENV RUSTUP_HOME=/opt/rust/rustup \
    CARGO_HOME=/opt/rust/cargo \
    PATH=/opt/rust/cargo/bin:$PATH

# Install dependencies
RUN set -eux; \
    dnf -y update && \
    dnf -y install --allowerasing \
    curl \
    git \
    gcc \
    gcc-c++ \
    glibc-devel \
    make \
    libarchive-devel \
    xz-devel \
    pkgconf \
    rpm-build \
    ca-certificates && \
    dnf clean all

# Install Rust
RUN curl https://static.rust-lang.org/rustup/archive/1.28.2/x86_64-unknown-linux-gnu/rustup-init -o rustup-init; \
    ls -al; \
    echo '20a06e644b0d9bd2fbdbfd52d42540bdde820ea7df86e92e533c073da0cdd43c *rustup-init' | sha256sum -c - && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain ${TOOLCHAIN} --default-host x86_64-unknown-linux-gnu && \
    rm rustup-init && \
    chmod -R a+w $RUSTUP_HOME $CARGO_HOME && \
    printf '[net] \ngit-fetch-with-cli = true\n' >> /opt/rust/cargo/config && \
    printf '[build] \ntarget = "x86_64-unknown-linux-gnu"\n' >> /opt/rust/cargo/config

# Install cargo-deb
RUN cargo install -f cargo-deb && \
    rm -rf /opt/rust/cargo/registry/

# Setup user and workspace
RUN mkdir -p /github && \
    useradd -m -d /github/home -u 1001 github

ADD entrypoint.sh cleanup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/cleanup.sh

USER github
WORKDIR /github/home

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
