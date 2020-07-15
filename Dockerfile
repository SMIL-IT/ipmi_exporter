FROM golang:1.14 AS builder
ADD . /go/src/github.com/soundcloud/ipmi_exporter/
WORKDIR /go/src/github.com/soundcloud/ipmi_exporter
RUN make

FROM buildpack-deps:bionic as freeipmi-builder
RUN apt-get update \
    && apt-get install -y libgcrypt20-dev
RUN wget https://ftp.gnu.org/gnu/freeipmi/freeipmi-1.6.5.tar.gz
RUN tar xaf freeipmi-*.tar.gz
WORKDIR /freeipmi-1.6.5
RUN ./configure
RUN make -j$(nproc)
RUN make install DESTDIR=/freeipmi-dest

FROM ubuntu:bionic
WORKDIR /
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgcrypt20 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=freeipmi-builder /freeipmi-dest /
COPY --from=builder /go/src/github.com/soundcloud/ipmi_exporter/ipmi_exporter /bin/ipmi_exporter

RUN ldconfig

EXPOSE 9290
ENTRYPOINT ["/bin/ipmi_exporter"]
CMD ["--config.file", "/config.yml"]
