#!/usr/bin/env bash

export BASE_DIR=$PWD

# Create a binary tree
mkdir ${HOME}/bin
pushd ${HOME}/bin

###  Download Cloudflare SSL binaries
wget -q  https://pkg.cfssl.org/R1.2/cfssl_linux-amd64   https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x cfssl_linux-amd64 cfssljson_linux-amd64
mv cfssl_linux-amd64 cfssl
mv cfssljson_linux-amd64 cfssljson
popd

# Create an etc tree for configs
mkdir ${HOME}/etc
pushd ${HOME}/etc

# Generate the K8S worker certificates
bash ${BASE_DIR}/cfssl-worker-certs.sh ${HOME}/etc

# Copy Kubernetes cluster configs to etc directory
sudo cp /etc/kubernetes/pki/ca.* ${HOME}/etc
sudo cp /etc/kubernetes/*.conf ${HOME}/etc
sudo chown $(id -u):$(id -g) $HOME/etc/ca.* ${HOME}/etc/*.conf
popd

# Create the Kubelet configs for each node
for nodes in nx-osv9000-1:172.16.30.101 nx-osv9000-2:172.16.30.102 nx-osv9000-3:172.16.30.103 nx-osv9000-4:172.16.30.104; do

    IP=$(echo ${nodes} | cut -d: -f2)
    NAME=$(echo ${nodes} | cut -d: -f1)

    kubectl config set-cluster kubernetes \
        --certificate-authority=${HOME}/etc/ca.crt \
        --embed-certs=true \
        --server=https://10.10.20.20:6443 \
        --kubeconfig=${HOME}/etc/${IP}-kubelet.yaml

    kubectl config set-credentials system:node:${IP} \
        --client-certificate=${HOME}/etc/${IP}.pem \
        --client-key=${HOME}/etc/${IP}-key.pem \
        --embed-certs=true \
        --kubeconfig=${HOME}/etc/${IP}-kubelet.yaml

    kubectl config set-context default \
        --cluster=kubernetes \
        --user=system:node:${IP} \
        --kubeconfig=${HOME}/etc/${IP}-kubelet.yaml

    kubectl config use-context default --kubeconfig=${HOME}/etc/${IP}-kubelet.yaml

done

# Copy the configuration directory to each switch
for i in $(seq 101 104); do \
    echo "Node ${i}"; \
    python3 ${BASE_DIR}/setup_k8s_dirs.py -t 172.16.30.${i}
    scp ${HOME}/etc/* admin@172.16.30.${i}:kubernetes/etc
done
