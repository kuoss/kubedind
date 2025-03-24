#!/bin/bash

API_SERVER_ADDRESS=$(docker exec "$KIND_CONTROL_PLANE" kubectl config view --kubeconfig=/etc/kubernetes/admin.conf --minify -o jsonpath='{.clusters[0].cluster.server}')
API_SERVER_HOST=$(echo "$API_SERVER_ADDRESS" | sed 's#https://##' | sed 's/:.*//')
API_SERVER_PORT=6443
TOKEN=$(docker exec "$KIND_CONTROL_PLANE" kubeadm token create --ttl 1h)
DISCOVERY_TOKEN_CA_CERT_HASH=$(docker exec "$KIND_CONTROL_PLANE" openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform DER 2>/dev/null | openssl sha256 -hex | sed 's/^.* //')

docker run --rm -it \
--name node01 \
--network kind \
--privileged \
--cgroupns=host \
-v /sys/fs/cgroup:/sys/fs/cgroup:rw \
-e API_SERVER_ADDRESS="$API_SERVER_ADDRESS" \
-e API_SERVER_HOST="$API_SERVER_HOST" \
-e API_SERVER_PORT="$API_SERVER_PORT" \
-e TOKEN="$TOKEN" \
-e DISCOVERY_TOKEN_CA_CERT_HASH="$DISCOVERY_TOKEN_CA_CERT_HASH" \
"$IMG"
