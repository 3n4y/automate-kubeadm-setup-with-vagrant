#!/bin/bash

# Setup for worker nodes

set -euxo pipefail #stop execution if any step fails
# Variable Declaration

KUBERNETES_VERSION="1.29"

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


lsmod | grep br_netfilter
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

# Install CRI-O Runtime

  OS="xUbuntu_22.04"

  VERSION="1.28"

  # Create the .conf file to load the modules at bootup
  cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
  overlay
  br_netfilter
EOF

  sudo modprobe overlay
  sudo modprobe br_netfilter

  # Set up required sysctl params, these persist across reboots.
  cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
  net.bridge.bridge-nf-call-iptables  = 1
  net.ipv4.ip_forward                 = 1
  net.bridge.bridge-nf-call-ip6tables = 1
EOF

  sudo sysctl --system

  cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
  deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
  cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
  deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

  curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
  curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

  sudo apt-get update
  sudo apt-get install cri-o cri-o-runc -y

  sudo systemctl daemon-reload
  sudo systemctl enable crio --now

  echo "CRI runtime installed successfully"


## Installing kubeadm, kubelet and kubectl 
#    sudo apt-get update && sudo apt-get install -y apt-transport-https curl
#    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
#    cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
#    deb https://apt.kubernetes.io/ kubernetes-xenial main
# EOF
   sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl gpg
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
   
   sudo apt-get update
   sudo apt-get install -y kubelet kubectl kubeadm
   sudo apt-mark hold kubelet kubeadm kubectl
   sudo apt-get install -y jq
   systemctl stop ufw
   systemctl disable ufw

sudo chmod +x /vagrant/cltjoincommand.sh
sudo /vagrant/cltjoincommand.sh
