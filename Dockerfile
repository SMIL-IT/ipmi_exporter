FROM golang:1.14 AS builder
RUN go env -w GO111MODULE=on && \
    go env -w GOPROXY=https://goproxy.cn,direct
ADD . /go/src/github.com/soundcloud/ipmi_exporter/
WORKDIR /go/src/github.com/soundcloud/ipmi_exporter
RUN make

FROM buildpack-deps:bionic as freeipmi-builder
RUN sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|security.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list
RUN apt-get update \
    && apt-get install -y libgcrypt20-dev
RUN wget https://ftp.gnu.org/gnu/freeipmi/freeipmi-1.6.5.tar.gz
RUN tar xaf freeipmi-*.tar.gz
WORKDIR /freeipmi-1.6.5
RUN ./configure
RUN make -j$(nproc)
RUN make install DESTDIR=/freeipmi-dest

FROM ubuntu:bionic
RUN sed -i 's|archive.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|security.ubuntu.com|mirrors.aliyun.com|g' /etc/apt/sources.list
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
