# Fedora 29 K8S Cluster Setup

# Add Kubernetes Management network
sudo nmcli conn modify ens192 ipv4.addr "172.16.30.100/24"

sudo hostnamectl set-hostname k8s-master
sudo nmcli conn down ens192
sudo nmcli conn up ens192

# "Out of Band" management network - not needed for normal environments
sudo nmcli conn down "Wired connection 1"
sudo nmcli conn modify "Wired connection 1" con-name ens224
sudo nmcli conn down ens224
sudo nmcli conn modify ens224 ipv4.method manual ipv4.addr "172.31.0.100/24" ipv4.dns "208.67.222.222,208.67.220.220" ipv4.gateway "172.31.0.1"
sudo nmcli conn up ens224

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
sudo systemctl start docker
sudo systemctl enable docker

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

export K8S_MASTER_IP=172.16.30.100
sudo kubeadm init \
    --apiserver-advertise-address=${K8S_MASTER_IP} \
    --node-name=${K8S_MASTER_IP} \
    --pod-network-cidr=192.168.0.0/16 \
    --service-cidr=172.16.30.192/27

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# NOTE:  NO SUDO - above kube config relocation negates need for sudo.  
kubectl apply -f https://docs.projectcalico.org/v3.7/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml

# MAYBE THIS WILL WORK TOO
# kubectl apply -f https://docs.projectcalico.org/v3.7/manifests/calico.yaml

#### OUTPUT OF KUBDADM COMMAND
cat > /dev/null <<EOF
[init] Using Kubernetes version: v1.14.1
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Activating the kubelet service
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [172.16.30.100 localhost] and IPs [172.16.30.100 127.0.0.1 ::1]
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [172.16.30.100 localhost] and IPs [172.16.30.100 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [172.16.30.100 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [172.16.30.193 172.16.30.100]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 20.502171 seconds
[upload-config] storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.14" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --experimental-upload-certs
[mark-control-plane] Marking the node 172.16.30.100 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node 172.16.30.100 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: 0m6mdn.0ix15pc9p0ldb261
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] creating the "cluster-info" ConfigMap in the "kube-public" namespace
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 172.16.30.100:6443 --token 0m6mdn.0ix15pc9p0ldb261 \
    --discovery-token-ca-cert-hash sha256:bac5ee6306c1b9bc848c409bfb584b8cd1ddfc1ae90455b5b3293bbe3a967e5a 

EOF
