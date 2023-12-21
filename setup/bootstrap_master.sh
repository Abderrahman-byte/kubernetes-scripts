#!/bin/bash
# Kubernetes control plane initialization script with Calico CNI.

# Define the Pod CIDR for the cluster
POD_CIDR="192.168.0.0/16"

# Pull required Kubernetes images
kubeadm config images pull

# Initialize the Kubernetes control plane
kubeadm init --control-plane-endpoint="$(hostname -f)" --pod-network-cidr=$POD_CIDR

# Install Calico CNI
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml

# Install Metrics Server
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
