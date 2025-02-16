# Stage 1: Build
FROM alpine:3.16 AS builder

# Install build dependencies
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libpcap-dev \
    make \
    autoconf \
    automake \
    wget \
    linux-headers

WORKDIR /build

# Download and build tcpdump with static linking
RUN wget https://www.tcpdump.org/release/tcpdump-4.99.4.tar.gz && \
    tar -xf tcpdump-4.99.4.tar.gz && \
    cd tcpdump-4.99.4 && \
    LDFLAGS='-static -L/usr/lib' ./configure --enable-static && \
    make LDFLAGS='-static -L/usr/lib'

# Stage 2: Minimal final image
FROM scratch

COPY --from=builder /build/tcpdump-4.99.4/tcpdump /tcpdump

ENTRYPOINT ["/tcpdump"]
