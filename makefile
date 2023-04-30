SHELL := /bin/bash

# ==============================================================================
# Testing running system

# Access metrics directly (8080) or through the sidecar (3001)
# expvarmon -ports=":8080" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"
# expvarmon -ports=":3030" -vars="build,requests,goroutines,errors,panics,mem:memstats.Alloc"

# Used to install expvarmon program for metrics dashboard.
# go install github.com/divan/expvarmon@latest


run:
	go run app/services/salesApi/main.go | go run app/tooling/logfmt/main.go

# Building containers

# Example: $(shell git rev-parse --short HEAD)
VERSION := 1.0

all: sales-api

sales-api:
	docker build \
		-f zarf/docker/dockerfile.salesApi \
		-t sales-api-amd64:$(VERSION) \
		--build-arg BUILD_REF=$(VERSION) \
		--build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
		.

# ==============================================================================
# Running from within k8s/kind
KIND_CLUSTER := starter-cluster

kind-up:
	kind create cluster \
		--image kindest/node:v1.21.1@sha256:69860bda5563ac81e3c0057d654b5253219618a22ec3a346306239bba8cfa1a6 \
		--name $(KIND_CLUSTER) \
		--config zarf/k8s/kind/kind-config.yaml
	kubectl config set-context --current --namespace=sales-system

kind-down:
	kind delete cluster --name $(KIND_CLUSTER)


kind-load:
	cd zarf/k8s/kind/sales-pod; kustomize edit set image sales-api-image=sales-api-amd64:$(VERSION)
	kind load docker-image sales-api-amd64:$(VERSION) --name $(KIND_CLUSTER)

kind-apply:
	kustomize build zarf/k8s/kind/sales-pod | kubectl apply -f -



kind-status:
	kubectl get nodes -o wide
	kubectl get svc -o wide
	kubectl get pods -o wide --watch --all-namespaces



kind-logs:
	kubectl logs -l app=sales --all-containers=true -f --tail=100 | go run app/services/salesApi/main.go | go run app/tooling/logfmt/main.go



kind-restart:
	kubectl rollout restart deployment sales-pod


kind-update: all kind-load kind-restart

kind-update-apply: all kind-load kind-apply

tidy:
	go mod tidy
	go mod vendor
