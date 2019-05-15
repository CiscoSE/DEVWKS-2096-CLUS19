sudo rsync -av /etc/kubernetes timmil@172.16.30.11:DEVWKS-2096-CLUS19/$(hostname -s)/etc/
sudo rsync -av /var/lib/kubelet --exclude 'kubelet/pods/*' timmil@172.16.30.11:DEVWKS-2096-CLUS19/$(hostname -s)/var.lib/
