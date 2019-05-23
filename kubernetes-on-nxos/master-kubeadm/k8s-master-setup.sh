#!/usr/bin/env bash

# IP Addressing specific to DEVNET Sandbox
export K8S_MASTER_IP=10.10.20.20
export SVC_CIDR=172.16.30.192/27
export K8S_VERSION=1.14.2
export CALICO_VERSION=3.7

# IP Addressing specific to Calico
export POD_CIDR=192.168.0.0/16

# DEVNET Sandbox K8S pre-requisites

# Disable SELINUX (default off in sandbox)
# Enable/start docker (default installed and enabled in sandbox)
# Disable all swap services
sudo /usr/sbin/swapoff -a
sudo /usr/bin/sed -i -e 's,.* swap .*,,' /etc/fstab

# Add Kubernetes YUM repository
sudo /usr/bin/bash -c 'cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
'

# Install Kubernetes binaries
sudo /usr/bin/yum install -y kubeadm kubelet kubectl

# Convert docker to use systemd based cgroups management, not native cgroupfs
sudo /usr/bin/sed -i -e 's,^ExecStart=/usr/bin/dockerd$,ExecStart=/usr/bin/dockerd --exec-opt native.cgroupdriver=systemd,' /usr/lib/systemd/system/docker.service
sudo /usr/bin/systemctl daemon-reload
sudo /usr/bin/systemctl restart docker

# Start the kubelet (it will fail to start, but loop trying to start)
sudo /usr/bin/systemctl enable kubelet
sudo /usr/bin/systemctl start kubelet

# Configure master (will configure the kubelet so it starts)
sudo /usr/bin/kubeadm init \
    --apiserver-advertise-address=${K8S_MASTER_IP} \
    --node-name=${K8S_MASTER_IP} \
    --pod-network-cidr=${POD_CIDR} \
    --service-cidr=${SVC_CIDR} \
    --experimental-upload-certs \
    --ignore-preflight-errors=NumCPU \
    | /usr/bin/tee kubeadm-master.output.txt | /usr/bin/grep 'kubeadm join'

# Need to record the kubeadm join command for potential future use

# Set up kubeconfig in user directory
/bin/mkdir -p $HOME/.kube
sudo /usr/bin/cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo /usr/bin/chown $(id -u):$(id -g) $HOME/.kube/config

# Set up kubeconfig in root directory
sudo /bin/mkdir -p /root/.kube
sudo /usr/bin/cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Set up Calico CNI
sudo /usr/bin/kubectl apply -f https://docs.projectcalico.org/v${CALICO_VERSION}/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

