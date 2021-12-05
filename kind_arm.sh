#!/bin/bash
#
# 
#

set -oe errexit

# desired cluster name; default is "kind"
KIND_CLUSTER_NAME="kind"


echo "> initializing Kind cluster: ${KIND_CLUSTER_NAME}"

# create a cluster 
cat <<EOF | kind create cluster  --image rossgeorgiev/kind-node-arm64:v1.20.0 --name "${KIND_CLUSTER_NAME}" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
        authorization-mode: "AlwaysAllow"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

echo "> 😊😊 Verify Cluster install"

kubectl wait --for=condition=Ready=true node/kind-control-plane --timeout=30s

kubectl get nodes 

##
## harbor
##

echo "> 😊😊 Install Harbor"📦

helm repo add harbor https://helm.goharbor.io

helm install local-harbor harbor/harbor --namespace harbor --create-namespace

echo "> 😊😊 Verify Harbor install"

kubectl -n harbor wait --for=condition=Ready pod/local-harbor-trivy-0 --timeout=60s

sleep 5

kubectl get pods -n harbor

echo "> 😊😊 done!"
