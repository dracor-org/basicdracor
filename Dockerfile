# basicDraCor in a container: QB64 Phoenix Edition (Linux build from the
# pinned release source), the library, demo and tests, and a bash shell.
#
#   docker build -t basicdracor .
#   docker run -it --rm basicdracor          # shell
#   docker run --rm basicdracor demo         # run the demo
# QB64-PE 4.7.0 supports Linux on x86 and x86_64 only (its Makefile passes
# -m64, which gcc on aarch64 rejects), so the image is always linux/amd64.
# On Apple Silicon Docker Desktop runs it emulated.
FROM --platform=linux/amd64 debian:bookworm-slim

ARG QB64PE_VERSION=4.7.0-GLFW
# SHA-256 of qb64pe_lnx-x64-${QB64PE_VERSION}.tar.gz (a source release)
ARG QB64PE_SHA256=4e2aeb61da9c41340890460f8e79c21305851ef8eb10a6f134939b5ab3273057

# Build dependencies as listed in QB64-PE's setup_lnx.sh for Debian
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential ca-certificates curl \
      mesa-common-dev libglu1-mesa-dev libasound2-dev libpng-dev \
      libcurl4-openssl-dev libx11-dev libxcursor-dev libxrandr-dev \
      libxinerama-dev libxi-dev \
 && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash dracor \
 && mkdir -p /opt/qb64pe /opt/basicdracor/bin \
 && chown -R dracor:dracor /opt/qb64pe /opt/basicdracor

USER dracor

# Download and build QB64-PE
RUN cd /tmp \
 && curl -fsSL -o qb64pe.tar.gz \
      "https://github.com/QB64-Phoenix-Edition/QB64pe/releases/download/v${QB64PE_VERSION}/qb64pe_lnx-x64-${QB64PE_VERSION}.tar.gz" \
 && echo "${QB64PE_SHA256}  qb64pe.tar.gz" | sha256sum -c - \
 && tar xzf qb64pe.tar.gz -C /opt \
 && rm qb64pe.tar.gz \
 && cd /opt/qb64pe \
 && { make OS=lnx BUILD_QB64=y -j"$(nproc)" >/tmp/qb64pe-build.log 2>&1 || { grep -m20 -B2 -A5 "rror" /tmp/qb64pe-build.log; exit 1; }; } \
 && test -x /opt/qb64pe/qb64pe \
 && rm /tmp/qb64pe-build.log

ENV QB64PE=/opt/qb64pe/qb64pe \
    BASICDRACOR_BIN=/opt/basicdracor/bin \
    QB64PE_NOPROMPT=y \
    PATH=/opt/basicdracor/bin:/opt/qb64pe:/home/dracor/basicdracor/scripts:$PATH

WORKDIR /home/dracor/basicdracor
COPY --chown=dracor:dracor . .

# Build demo and tests as console programs
RUN scripts/build.sh examples/demo.bas tests/test_dracor.bas \
 && cp docker/welcome.sh /home/dracor/.basicdracor-welcome \
 && echo '. ~/.basicdracor-welcome' >> /home/dracor/.bashrc

CMD ["bash"]
