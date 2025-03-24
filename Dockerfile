FROM golang:1.23-alpine AS builder

RUN apk add git make bash

WORKDIR /build
RUN git clone https://github.com/Mirantis/cri-dockerd && \
    cd cri-dockerd && \
    make cri-dockerd

FROM docker:28.0

RUN apk add --no-cache kubeadm kubectl kubelet
# RUN apk add --no-cache iptables conntrack

COPY --from=builder /build/cri-dockerd/cri-dockerd /usr/local/bin/cri-dockerd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
