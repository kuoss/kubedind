#!/bin/sh
set -x

echo "[entrypoint] Starting dockerd..."
dockerd --host=unix:///var/run/docker.sock &

echo "[entrypoint] Waiting for dockerd..."
until docker info >/dev/null 2>&1; do sleep 1; done

echo "[entrypoint] Starting cri-dockerd..."
cri-dockerd &

sleep 1

if [ -f /etc/kubernetes/kubelet.conf ]; then
    echo "Node already joined. Skipping kubeadm join..."
else
    echo "Node is not joined. Running kubeadm join..."
    timeout 2s kubeadm join "$API_SERVER_HOST:$API_SERVER_PORT" \
        --token "$TOKEN" \
        --discovery-token-ca-cert-hash "sha256:$DISCOVERY_TOKEN_CA_CERT_HASH" \
        --cri-socket=unix:///var/run/cri-dockerd.sock \
        --ignore-preflight-errors=all
fi

ln -s /var/lib/docker/engine-id /etc/machine-id
sed -i 's|containerRuntimeEndpoint: ""|containerRuntimeEndpoint: "unix:///var/run/cri-dockerd.sock"|' /var/lib/kubelet/config.yaml
sed -i 's|cgroupDriver: systemd|cgroupDriver: cgroupfs|' /var/lib/kubelet/config.yaml

mkdir -p /sys/fs/cgroup/cpu
mount -t cgroup -o cpu,cpuacct cgroup /sys/fs/cgroup/cpu
mkdir -p /sys/fs/cgroup/cpuset
mount -t cgroup -o cpuset cgroup /sys/fs/cgroup/cpuset

echo "[entrypoint] Starting kubelet..."
kubelet \
    --config=/var/lib/kubelet/config.yaml \
    --kubeconfig=/etc/kubernetes/kubelet.conf \
    --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
    --pod-infra-container-image=registry.k8s.io/pause:3.6 \
    --v=2

sleep infinity
