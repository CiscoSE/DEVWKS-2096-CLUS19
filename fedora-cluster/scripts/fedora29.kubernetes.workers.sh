# Fedora 29 K8S Cluster Setup

# Add external OOB Management network

# Worker 1
sudo nmcli conn modify ens192 ipv4.addr "172.16.30.101/24"
sudo hostnamectl set-hostname k8s-worker-1
sudo nmcli conn down ens192
sudo nmcli conn up ens192

sudo nmcli conn down "Wired connection 1"
sudo nmcli conn modify "Wired connection 1" con-name ens224
sudo nmcli conn modify ens224 ipv4.method manual ipv4.addr "172.31.0.101/24" ipv4.dns "208.67.222.222,208.67.220.220" ipv4.gateway "172.31.0.1"
sudo nmcli conn up ens224

# Worker 2
sudo nmcli conn modify ens192 ipv4.addr "172.16.30.102/24"
sudo hostnamectl set-hostname k8s-worker-2
sudo nmcli conn down ens192
sudo nmcli conn up ens192

sudo nmcli conn down "Wired connection 1"
sudo nmcli conn modify "Wired connection 1" con-name ens224
sudo nmcli conn modify ens224 ipv4.method manual ipv4.addr "172.31.0.102/24" ipv4.dns "208.67.222.222,208.67.220.220" ipv4.gateway "172.31.0.1"
sudo nmcli conn up ens224

# Worker 3
sudo nmcli conn modify ens192 ipv4.addr "172.16.30.103/24"
sudo hostnamectl set-hostname k8s-worker-3
sudo nmcli conn down ens192
sudo nmcli conn up ens192

sudo nmcli conn down "Wired connection 1"
sudo nmcli conn modify "Wired connection 1" con-name ens224
sudo nmcli conn modify ens224 ipv4.method manual ipv4.addr "172.31.0.103/24" ipv4.dns "208.67.222.222,208.67.220.220" ipv4.gateway "172.31.0.1"
sudo nmcli conn up ens224

# Worker 4
sudo nmcli conn modify ens192 ipv4.addr "172.16.30.104/24"
sudo hostnamectl set-hostname k8s-worker-4
sudo nmcli conn down ens192
sudo nmcli conn up ens192

sudo nmcli conn down "Wired connection 1"
sudo nmcli conn modify "Wired connection 1" con-name ens224
sudo nmcli conn modify ens224 ipv4.method manual ipv4.addr "172.31.0.104/24" ipv4.dns "208.67.222.222,208.67.220.220" ipv4.gateway "172.31.0.1"
sudo nmcli conn up ens224

sudo su -c "cat >> /etc/hosts <<EOF
172.16.30.100   k8s-master
172.16.30.101   k8s-worker-1
172.16.30.102   k8s-worker-2
172.16.30.103   k8s-worker-3
172.16.30.104   k8s-worker-4
EOF
"

# Update system
sudo dnf update -y 

# Switch to Docker CE Edition
sudo dnf -y install dnf-plugins-core

sudo dnf remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine

sudo dnf install -y docker-ce docker-ce-cli containerd.io

# Switch Docker to systemd cgroup management (for K8S sake)
sudo su -c 'cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF
'

sudo mkdir -p /etc/systemd/system/docker.service.d
sudo systemctl daemon-reload
sudo systemctl enable docker
sudo systemctl restart docker

# Clean up for Kubernetes
sudo systemctl disable firewalld
sudo systemctl stop firewalld

sudo swapoff -a
sudo sed -i -e 's,.* swap .*,,' /etc/fstab

# Setup Kubernetes Repo
sudo su -c "cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
"

sudo chmod 0644 /etc/yum.repos.d/kubernetes.repo

sudo dnf install -y kubeadm kubectl kubelet
sudo systemctl enable kubelet.service

sudo kubeadm join 172.16.30.100:6443 --token 0m6mdn.0ix15pc9p0ldb261 \
    --discovery-token-ca-cert-hash sha256:bac5ee6306c1b9bc848c409bfb584b8cd1ddfc1ae90455b5b3293bbe3a967e5a 

mkdir ${HOME}/.kube
scp 172.16.30.100:.kube/config ${HOME}/.kube/config

kubectl get nodes

