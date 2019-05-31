#!/usr/bin/env bash

# IP Addressing specific to DEVNET Sandbox
export K8S_MASTER_IP=10.10.20.20
export SVC_CIDR=10.10.20.64/27
export K8S_VERSION=1.13.6
export CALICO_VERSION=3.7

# Default to using Flannel for CNI
if [ x"$1" == "x" ]; then
    CNI_STYLE="flannel"
else
    CNI_STYLE="$1"
fi

if [ "${CNI_STYLE}" == "flannel" ]; then
    export POD_CIDR="10.244.0.0/16"
    export CNI_URL="https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml"
elif [ "${CNI_STYLE}" == "calico" ]; then
    export POD_CIDR="192.168.0.0/16"
    export CNI_URL="https://docs.projectcalico.org/v${CALICO_VERSION}/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml"
else
    echo "Unsupported CNI - ${CNI_STYLE}"
    exit 1
fi

###
# DEVNET Sandbox K8S pre-requisites
###

# Disable SELINUX (default off in sandbox)
sudo /usr/sbin/setenforce 0
sudo /usr/bin/sed -i -e 's,^SELINUX=.*$,SELINUX=disabled,g' /etc/sysconfig/selinux

# Enable/start docker (default installed and enabled in sandbox)
# Disable all swap services
sudo /usr/sbin/swapoff -a
sudo /usr/bin/sed -i -e 's,.* swap .*,,' /etc/fstab

# Disable IPv6 routing
sudo /usr/sbin/sysctl net.ipv6.conf.all.disable_ipv6=1
sudo bash -c "echo 'net.ipv6.conf.all.disable_ipv6 = 1' > /etc/sysctl.d/10-disable-ipv6.conf"

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
sudo /usr/bin/yum install -y kubeadm-${K8S_VERSION}-0 kubelet-${K8S_VERSION}-0 kubectl-${K8S_VERSION}-0

# Convert docker to use systemd based cgroups management, not native cgroupfs
sudo /usr/bin/sed -i -e 's,^ExecStart=/usr/bin/dockerd$,ExecStart=/usr/bin/dockerd --exec-opt native.cgroupdriver=systemd,' /usr/lib/systemd/system/docker.service
sudo /usr/bin/systemctl daemon-reload
sudo /usr/bin/systemctl restart docker

# Start the kubelet (it will fail to start, but loop trying to start)
sudo /usr/bin/systemctl enable kubelet

###
# End Pre-Requisites for CentOS 7
###

# Because of Sandbox networking persnicketiness, keep pulling until status 0
TEST=1
while [ ${TEST} -ne 0 ]; do
    /usr/bin/kubeadm config images pull | /usr/bin/tee -a kubeadm-master.pull.output.txt
    TEST=$?
done

# Configure master (will configure the kubelet so it starts)
sudo /usr/bin/kubeadm init \
    --apiserver-advertise-address=${K8S_MASTER_IP} \
    --node-name=${K8S_MASTER_IP} \
    --pod-network-cidr=${POD_CIDR} \
    --service-cidr=${SVC_CIDR} \
    --ignore-preflight-errors=NumCPU \
    | /usr/bin/tee -a kubeadm-master.output.txt | /usr/bin/grep 'kubeadm join'

# Need to record the kubeadm join command for potential future use

# Set up kubeconfig in user directory
/bin/mkdir -p $HOME/.kube
sudo /usr/bin/cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo /usr/bin/chown $(id -u):$(id -g) $HOME/.kube/config

# Set up kubeconfig in root directory
sudo /bin/mkdir -p /root/.kube
sudo /usr/bin/cp -i /etc/kubernetes/admin.conf /root/.kube/config

# Set up CNI
sudo /usr/bin/kubectl apply -f "${CNI_URL}"

