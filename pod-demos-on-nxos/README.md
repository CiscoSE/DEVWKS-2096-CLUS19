# Demos on Kubernetes in NX-OS

## Current Limitations

* Flannel container networking 
* Host port binding

# Commands for inspecting environment

```bash
### List of nodes in the cluster
kubectl get nodes

### Details of a particular node
kubectl describe nodes 172.16.30.101

### Deployments in the cluster
kubectl get deployments -o wide

### Pods deployed in the cluster
kubectl get pods -o wide

```

# Scenarios

## Random pod placement

This demo simply publishes a Deployment to the cluster with no
constraints, letting Kubernetes place the pod and its containers
whereever there are available resources.

```bash
kubectl apply -f random-demo-pod.yml
```

## Targeted pod placement via labels

This demo leverages the default labels that Kubernetes automatically
applies to nodes in the cluster, namely: kubernetes.io/hostname

```bash
kubectl apply -f label-demo-pod.yml
```

## Targeted pod placement via taints/tolerations


```bash
kubectl apply -f taint-demo-pod.yml
```

## Global pod placement via DaemonSet

```bash
kubectl apply -f daemonset-demo-pod.yml
```

## Upgrade to version 2

```bash
kubectl apply -f daemonset-demo-pod-v2.yml
```

# Useful References

* [Assigning Pod to a Node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
* [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
* [Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)
* 
https://www.youtube.com/watch?v=6v_BDHIgOY8&feature=youtu.be
https://kubernetes.io/docs/concepts/configuration/overview/
https://www.slideshare.net/weaveworks/introduction-to-the-container-network-interface-cni
https://www.dasblinkenlichten.com/understanding-cni-container-networking-interface/

# Useful Commands

* Connect into a **running** pod

```bash
kubectl exec -it hello-pod /bin/shsh

```

* Run commands in a **running** pod

```bash
kubectl exec hello-pod ps aux
```

-------------

= Node Tainting =

```bash
kubectl taint nodes 172.16.30.101 switch=node1:NoSchedule
kubectl taint nodes 172.16.30.102 switch=node2:NoSchedule
kubectl taint nodes 172.16.30.103 switch=node3:NoSchedule
kubectl taint nodes 172.16.30.104 switch=node4:NoSchedule
```