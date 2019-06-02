# Kubernetes on NX-OS

= Overview =
A fairly scripted process for deploying a Kubernetes cluster that
leverages NX-OS switches as worker nodes.  The master nodes is
assumed to be a Linux server.  In this DEVNET Workshop session,
we leverage the DEVNET Sandbox environment for the resources
we need.

= Prerequisites =

* NX-OS version 9.2(1)
  * Nexus 9000 switches with >8GB RAM
  * Nexus 9000v virtual switch
  * Either: HTTP support enabled (preferred)
  * Or: Supported CA signed SSL certificate
* Docker 1.13.1 or newer
* Kubernetes 1.13.6

= Requirements for this Exercise =

* [DEVNET Sandbox “Open NX-OS with Nexus 9Kv Lab” Reservation](https://devnetsandbox.cisco.com/)
* VPN Connection into the Sandbox

= Instructions =

== DEVBOX Server - Kubernetes Master ==

* SSH into the DEVBOX jumphost

```bash
ssh developer@10.10.20.20
```

* Activate the Python virtual environment

```bash
source ~/code/sbx_nxos/venv/bin/activate
```

* Checkout this repository

```bash
cd ${HOME}/code
git clone https://github.com/CiscoSE/DEVWKS-2096-CLUS19
```

* Run script to create Kubernetes master (may take a few minutes)

```bash
pushd ${HOME}/code/DEVWKS-2096-CLUS19/kubernetes-on-nxos/master-kubeadm
bash k8s-master-setup.sh
popd
```

* Check the [master-kubeadm README.md](master-kubeadm/README.md) for validation commands and output

== DEVBOX Server - Kubernetes Worker Configs ==

* Note: you will be prompted for the Nexus 9000v admin user password for each host

```
pushd ${HOME}/code/DEVWKS-2096-CLUS19/kubernetes-on-nxos/worker-configs

# Verify N9Ks up and SSH host keys cached
for i in $(seq 101 104); do \
    echo "Node ${i}"; \
    ssh admin@172.16.30.${i} run bash hostname
done

# Generate the client configs/certificates
ln -s ../nxapi .
bash -x k8s-client-configs.sh
popd
```

== Nexus 9000v - Kubernetes Worker Deployment ==

* Pre-requisite: [Deploy Docker on NX-OS](../docker-on-nxos/README.md)
