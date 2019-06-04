#!/usr/bin/env bash
###
###  Note:  Even though framework for using Calico is in place,
###  Calico CNI functionality has not been tested at this time.
###  Only Flannel is supported today.
###

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

# Make sure package installation had no errors
if [ "$?" -ne "0" ]; then
    echo "Exiting script on Kubernetes package installation errors"
    exit 1
fi

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
    /usr/bin/kubeadm config images pull --kubernetes-version ${K8S_VERSION}
    TEST=$?
done

# Configure master (will configure the kubelet so it starts)
sudo /usr/bin/kubeadm init \
    --kubernetes-version ${K8S_VERSION} \
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

# Add Service Account to Admission Plugins
sudo sed -i -e 's/plugins=NodeRestriction$/plugins=NodeRestriction,ServiceAccount/' /etc/kubernetes/manifests/kube-apiserver.yaml 

# Need to pause long enough for all containers come online (safety first)
sleep 90

# Ideally, you just reboot.  But, we are scripting this... so, stop the kubelet
sudo systemctl stop kubelet

# Stop docker - killing all Kubernetes components
sudo systemctl stop docker
sleep 5

# Start Docker and clean up stopped containers
sudo systemctl start docker
sudo bash -c "docker ps -a | awk '/Exited/ {print \$NF;}' | xargs -n1 docker rm"

# Start the Kubelet so it fires up all the Kubernetes control plane (/etc/kubernetes/manifests)
sudo systemctl start kubelet

# Set up CNI - wait 75 seconds for control plane to come online
echo "Waiting 90 seconds for Kubernetes control plane to stabilize"
sleep 90
echo "... Proceeding with CNI installation ..."

# If Flannel, we need to make YAML changes
if [ "${CNI_STYLE}" == "flannel" ]; then
    wget -q -O kube-flannel.yml "${CNI_URL}"
    /usr/bin/sed -i -e 's,privileged: false,privileged: true,; s/vxlan/udp/' kube-flannel.yml
    sudo /usr/bin/kubectl apply -f kube-flannel.yml
else
    sudo /usr/bin/kubectl apply -f "${CNI_URL}"
fi

