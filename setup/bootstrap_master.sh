#!/bin/bash
# Kubernetes control plane initialization script with Calico CNI.

# Define the Pod CIDR for the cluster
POD_CIDR="192.168.0.0/16"

# Pull required Kubernetes images
kubeadm config images pull

# Initialize the Kubernetes control plane
kubeadm init --control-plane-endpoint="$(hostname -f)" --pod-network-cidr=$POD_CIDR

# Install Calico CNI
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# Untaint nodes to allow scheduling control plane components
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
kubectl taint nodes --all node-role.kubernetes.io/master-
