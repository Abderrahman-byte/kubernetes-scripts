#!/bin/bash

# Common bootstrap script for setting up a Debian-based Kubernetes node.

# Set options for robust script execution: exit on error, treat unset variables as errors,
# enable debugging output, and handle pipeline failures.
set -euxo pipefail

# Configure containerd modules to load on system startup
cat <<EOF | tee /etc/modules-load.d/containerd.conf > /dev/null 2>&1
overlay
br_netfilter
EOF

# Load required kernel modules
modprobe overlay
modprobe br_netfilter

# Configure kernel parameters for Kubernetes and container runtime
cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf > /dev/null 2>&1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply the changes immediately
sysctl --system

# Update and upgrade system packages
apt update && apt upgrade -y

# Install essential packages for development and networking
apt install -y vim net-tools apt-transport-https ca-certificates curl gpg jq

# Download and install Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository to sources list
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null 2>&1

# Update package information
apt update

# Install containerd
apt install -y containerd.io

# Configure containerd and enable Systemd Cgroup
containerd config default | tee /etc/containerd/config.toml > /dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# Restart and enable containerd service
systemctl restart containerd
systemctl enable --now containerd

# Download and install Kubernetes GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add Kubernetes repository to sources list
cat <<EOF | tee /etc/apt/sources.list.d/kubernetes.list > /dev/null 2>&1
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /
EOF

# Update package information
apt update

# Install Kubernetes components
apt install -y kubelet kubeadm kubectl

# Mark Kubernetes components on hold to prevent accidental upgrades
apt-mark hold kubelet kubeadm kubectl

# Extract local IP address from eth0 interface
local_ip="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"

# Set KUBELET_EXTRA_ARGS in /etc/default/kubelet with the node IP
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
