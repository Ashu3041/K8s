#!/bin/bash

set -e

echo "==============================="
echo " Updating system"
echo "==============================="

sudo apt update
sudo apt upgrade -y

echo "==============================="
echo " Disabling swap"
echo "==============================="

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "==============================="
echo " Loading kernel modules"
echo "==============================="

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

echo "==============================="
echo " Configuring sysctl"
echo "==============================="

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "==============================="
echo " Installing containerd"
echo "==============================="

sudo apt install -y containerd

sudo mkdir -p /etc/containerd

containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd

echo "==============================="
echo " Installing Kubernetes"
echo "==============================="

sudo apt install -y apt-transport-https ca-certificates curl gpg

sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
| sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
| sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update

sudo apt install -y kubelet kubeadm kubectl

sudo apt-mark hold kubelet kubeadm kubectl

echo "==============================="
echo " Installing Tailscale"
echo "==============================="

curl -fsSL https://tailscale.com/install.sh | sh

echo
echo "==============================================="
echo " Worker setup completed successfully."
echo "==============================================="
echo
echo "Run:"
echo
echo "sudo tailscale up"
echo
echo "Then login in the browser."
echo
echo "Finally execute the kubeadm join command"
echo "generated on the master node."
