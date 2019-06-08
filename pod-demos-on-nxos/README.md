# Demos on Kubernetes in NX-OS

## Current Limitations

* Flannel container networking
* hostNetwork port binding only
* Avoid ReplicaSets because of hostNetwork

# Commands for inspecting environment

```bash
### List of nodes in the cluster
kubectl get nodes

### Details of a particular node
kubectl describe nodes 172.16.30.101

### DaemonSets in the cluster
kubectl get ds -o wide

### Details of a particular DaemonSet
kubectl describe ds demo-ds

### Deployments in the cluster
kubectl get deployments -o wide

### Details of a particular deployment
kubectl describe deployment demo-deploy

### Pods deployed in the cluster
kubectl get pods -o wide

### Details of a particular pod
kubectl describe deployment demo-pod

### See a pattern here?
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

## Global pod placement via DaemonSet

This demo showcases Kuberenets DaemonSets to deploy one pod on EVERY
node in the cluster.  Only taints prevent pod placement on a node...
unless the pod in the DaemonSet tolerates it.

Be sure to delete the previous deployments and let them clean up before
creating the DaemonSet on the cluster.

```bash
kubectl apply -f daemonset-demo-pod.yml
```

## Upgrade to version 2

Before running this command, be sure to look at the pods that
are currently deployed and notice their full names.

```bash
kubectl apply -f upgrade-demo-pod.yml
```

## Targeted pod placement via taints/tolerations

Because of time constraints, this demonstration and explaination
of Kubernetes taints and tolerations was omitted.  The instructions
below show the steps to demonstrate the application of the
taint/toleration mechanism.  For more information on taints/tolerations,
see the link below in the references section.

```bash
# Remove all existing pods, deployments, daemonsets - don't forget to
# wait a sufficient amount of time between commands to let Kubernetes
# do its work and clean up the containers.
kubectl get ds -o name | xargs -n1 kubectl delete
kubectl get deployments -o name | xargs -n1 kubectl delete
kubectl get pods -o name | xargs -n1 kubectl delete

# Taint all the worker nodes
for i in 1 2 3 4; do \
    kubectl taint nodes 172.16.30.10${i} switch=node${i}:NoSchedule
done

# Demo deployment without toleration
kubectl apply -f random-demo-pod.yml

# Examine deployment
kubectl describe deployment demo-deploy

# Deploy tolerant deployment
kubectl apply -f taint-demo-pod.yml

# Watch where it landed
kubectl get deployments -o wide
kubectl get pods -o wide

```

# Useful References

* [Assigning Pod to a Node](https://kubernetes.io/docs/concepts/configuration/assign-pod-node/)
* [Labels and Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
* [Taints and Tolerations](https://kubernetes.io/docs/concepts/configuration/taint-and-toleration/)
* [Updating a Deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)

# Appendix: Other Useful Commands

* Connect into a **running** pod

```bash
kubectl exec -it hello-pod /bin/shsh

```

* Run commands in a **running** pod

```bash
kubectl exec hello-pod ps aux
```
