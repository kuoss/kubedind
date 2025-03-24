IMG ?= kubedind:latest
KIND_CLUSTER ?= kind-kubedind
KIND_CONTROL_PLANE ?= kind-kubedind-control-plane

.PHONY: build
build:
	docker build -t $(IMG) .

.PHONY: cluster
cluster:
	kind create cluster --name $(KIND_CLUSTER)

.PHONY: node
node:
	IMG=$(IMG) KIND_CONTROL_PLANE=$(KIND_CONTROL_PLANE) ./node.sh

.PHONY: check
check:
	kubectl get nodes

.PHONY: clean
clean:
	kind delete cluster --name $(KIND_CLUSTER)
