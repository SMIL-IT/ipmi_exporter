# Build /go/bin/ipmi_exporter
FROM golang:1.15 AS builder
ADD . /go/src/github.com/soundcloud/ipmi_exporter/
RUN cd /go/src/github.com/soundcloud/ipmi_exporter && make

# Container image
FROM debian:buster
WORKDIR /
RUN apt-get update \
    && apt-get install freeipmi-tools -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /go/src/github.com/soundcloud/ipmi_exporter/ipmi_exporter /bin/ipmi_exporter

EXPOSE 9290
ENTRYPOINT ["/bin/ipmi_exporter"]
CMD ["--config.file", "/config.yml"]
