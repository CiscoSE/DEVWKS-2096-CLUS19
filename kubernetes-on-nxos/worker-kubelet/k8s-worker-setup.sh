#!/bin/bash
#
#  This script designed to run within NX-OS bash shell.
#
#  Script execution requires running in the management netns via:
#    ip netns exec management k8s-worker-setup.sh
#

# Define some variables
export K8S_VERSION=1.13.6
export CRI_VERSION=1.13.0
export CNI_VERSION=0.8.0
export K8S_DIR=/bootflash/kubernetes
export K8S_ETC=${K8S_DIR}/etc

# Skip some initialization steps if not needed
if ! /usr/bin/test -d /var/lib/docker/kubernetes/manifests; then
    echo "Creating persistent storage for Kubernetes"

    # Linked /var/lib/kubelet into /var/lib/docker/kubelet
    mkdir -p /var/lib/docker/kubelet
    ln -s /var/lib/docker/kubelet /var/lib/kubelet

    # Make persistent storage for the CNI configs
    mkdir -p /var/lib/docker/cni/etc/net.d
    ln -s /var/lib/docker/cni/etc /etc/cni

    # Make persistent storage for the CNI binaries
    mkdir -p /var/lib/docker/cni/bin
    ln -s /var/lib/docker/cni /opt/cni

    # Make persistent storage for the Kubernetes configs
    mkdir -p /var/lib/docker/kubernetes
    mkdir -p /var/lib/docker/kubernetes/manifests
    mkdir -p /var/lib/docker/kubernetes/pki
    ln -s /var/lib/docker/kubernetes /etc/kubernetes
    cp ${K8S_ETC}/admin.conf /var/lib/docker/kubernetes

fi

# Obtain my IP (changing netns redundant but left in for safety)
export MY_IP=$(ip netns exec management ip addr show eth1 | awk '/inet/ { print $2; }' | cut -d/ -f1)

# Copy in initial configurations
cp ${K8S_ETC}/${MY_IP}-kubelet.yaml /var/lib/docker/kubernetes
cp ${K8S_ETC}/ca.crt /var/lib/docker/kubernetes/pki

#  Download kubectl, kubelet, and kubeadm
if ! /usr/bin/test -f /usr/bin/kubectl; then 
    curl -o kubectl -k https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubectl
    curl -o kubelet -k https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubelet
    curl -o kubeadm -k https://storage.googleapis.com/kubernetes-release/release/v${K8S_VERSION}/bin/linux/amd64/kubeadm
    chmod +x kubectl kubelet kubeadm
    cp kube* /usr/bin
    mv kube* /bootflash/kubernetes/bin 
fi

#  Download CNI tools
if ! /usr/bin/test -f /usr/bin/crictl; then
    wget -q https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRI_VERSION}/crictl-v${CRI_VERSION}-linux-amd64.tar.gz
    wget -q https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz

    tar -xvf cni-plugins-linux-amd64-v${CNI_VERSION}.tgz -C /opt/cni/bin
    tar -xvf crictl-v${CRI_VERSION}-linux-amd64.tar.gz -C ${K8S_DIR}/bin
    tar -xvf crictl-v${CRI_VERSION}-linux-amd64.tar.gz -C /usr/bin
fi

#  Bring the cluster kubeconfig file into admin user's environment
mkdir -p ${HOME}/.kube
cp ${K8S_ETC}/admin.conf ${HOME}/.kube/config

# Get the Kubernetes cluster DNS Service IP
export DNS_IP=$(ip netns exec management kubectl get services -n kube-system | awk '/kube-dns/ { print $3; }')

# As a precaution, let's ensure the Docker engine is started 
# correctly with the shared /var/lib/docker mount point
if ! /usr/bin/test -f ${K8S_ETC}/etc/docker.remounted
    # Make sure we schedule I/O flush to disk 
    sync

    # Wait and sync again
    sleep 2
    sync

    # Stop Docker
    service docker stop

    # Make sure it unmounted /var/lib/docker
    mount | grep -q docker

    if [ "$?" -eq "0" ]; then
        echo "Error shutting down docker"
        exit 1
    fi

    # Start Docker
    service docker start
    sleep 2

    # Make notice we've been here already
    touch ${K8S_ETC}/etc/docker.remounted
fi

# Fire up the kubelet
nohup /usr/bin/kubelet --register-node=true \
    --hostname-override="${MY_IP}" \
    --node-ip="${MY_IP}" \
    --address="${MY_IP}" \
    --cluster-dns="${DNS_IP}" \
    --feature-gates="SupportPodPidsLimit=False" \
    --allow-privileged=true \
    --kubeconfig=/etc/kubernetes/${MY_IP}-kubelet.yaml > ${K8S_DIR}/kubelet.log 2>&1 < /dev/null &

