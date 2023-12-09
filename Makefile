version=0.1.0
registry=eigr

operator-image=${registry}/flame-k8s-controller:${version}

.PHONY: all

all: build test build-all-images

clean:
	mix deps.clean --all

clean-all:
	mix deps.clean --all && kind delete cluster --name default

build:
	mix deps.get && mix compile

build-operator-image:
	docker build --no-cache -f Dockerfile-operator -t ${operator-image} .

build-all-images:
	docker build --no-cache -f Dockerfile-operator -t ${operator-image} .

test-spawn:
	MIX_ENV=test elixir --name flame_k8s@127.0.0.1 -S mix test

test-operator:
	cd spawn_operator/spawn_operator && MIX_ENV=test mix deps.get && MIX_ENV=test elixir --name flame_k8s_controller@127.0.0.1 -S mix test

push-all-images:
	docker push ${operator-image}

create-minikube-cluster:
	minikube start

create-kind-cluster:
	kind create cluster -v 1 --name default --config kind-cluster-config.yaml
	kubectl cluster-info --context kind-default

delete-kind-cluster:
	kind delete cluster --name default

load-kind-images:
	kind load docker-image ${operator-image} --name default

create-k8s-namespace:
	kubectl create ns flame

generate-k8s-manifests:
	cd flame_k8s_controller && MIX_ENV=prod mix deps.get && MIX_ENV=prod mix bonny.gen.manifest --image ${operator-image} --namespace flame

apply-k8s-manifests:
	kubectl -n flame apply -f flame_k8s_controller/manifest.yaml