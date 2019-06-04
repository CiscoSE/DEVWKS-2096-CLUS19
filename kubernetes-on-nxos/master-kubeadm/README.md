# Kubernetes Master setup using kubeadm

## Pre-requisities

* You must make sure the time on the DEVBOX is correct.  It does not appear to honor DST.

```bash
# Check the date
date

# If the date is an hour off, run this command
sudo date -s "$(date --date='1 hour ago')"
sudo hwclock --systohc
```

## Instructions

```bash
bash k8s-master-setup.sh
```

## Validation

* Takes about 60-75 seconds for everything to settle down

### Cluster Nodes

```bash
$ kubectl get nodes
NAME          STATUS   ROLES    AGE   VERSION
10.10.20.20   Ready    master   13m   v1.13.6 
```

### Cluster System Daemonsets

```bash
$ kubectl -n kube-system get daemonset
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                     AGE
kube-flannel-ds-amd64     1         1         1       1            1           beta.kubernetes.io/arch=amd64     13m
kube-flannel-ds-arm       0         0         0       0            0           beta.kubernetes.io/arch=arm       13m
kube-flannel-ds-arm64     0         0         0       0            0           beta.kubernetes.io/arch=arm64     13m
kube-flannel-ds-ppc64le   0         0         0       0            0           beta.kubernetes.io/arch=ppc64le   13m
kube-flannel-ds-s390x     0         0         0       0            0           beta.kubernetes.io/arch=s390x     13m
kube-proxy                1         1         1       1            1           <none>                            14m
```

### Cluster System Deployments

```bash
$ kubectl -n kube-system get deployments
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   2/2     2            2           14m
```

### Cluster System Pods

```bash
$ kubectl -n kube-system get pods
NAME                                  READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-bg264              1/1     Running   0          15m
coredns-86c58d9df4-sbsbt              1/1     Running   0          15m
etcd-10.10.20.20                      1/1     Running   0          14m
kube-apiserver-10.10.20.20            1/1     Running   0          15m
kube-controller-manager-10.10.20.20   1/1     Running   0          15m
kube-flannel-ds-amd64-wk5m5           1/1     Running   0          15m
kube-proxy-bjg97                      1/1     Running   0          15m
kube-scheduler-10.10.20.20            1/1     Running   0          15m
```
