# Docker setup and configuration

The defaults for the config_docker.py script are set
for use with the DEVNET Sandbox demonstration for this
session (Open NX-OS with Nexus 9000v on VIRL).

# Local Vagrant Demonstration

However, if you'd like to run this script against a
local Nexus 9000v instance, you'll need the Vagrant box
image available at cisco.com.

## Vagrant box image setup

```bash
vagrant box add base nxosv.9.2.3.box
```
 
## Start the Nexus 9000v box image

```bash
vagrant up
```

## Connect to the serial console port (separate window)

```bash
telnet localhost 2023
```

## Configure Nexus 9000v (inital NXAPI setup)
 
Once Vagrant completes loading the Nexus 9000v, NXAPI needs
to be enabled.

```bash
# Use Vagrant to SSH into Nexus 9000v
vagrant ssh

! NX-OS COMMANDS HERE
configure terminal

feature nxapi
nxapi http port 80
end

copy running-config startup-config
exit
```

## Configure Docker on local Nexus 9000v

You'll need to have a Python virtual environment with a
minimum of Python 3.6 installed within it.

```bash
# Setup Virtual Environment
source ~/workspace/venv/bin/activate

# Configure Docker
python3 config_docker.py -t 127.0.0.1 -p 8080
```

## Demonstrate CPU protections on local Nexus 9000v

The above script places the Docker daemon into the /ext_ser/ cgroup
that contains CPU usage to 40% (per core).  This demo will simply
demonstrate that the CPU load is properly capped.

* Session 1: SSH into a switch and run top

```bash
# Run command from DEVWKS-2096-CLUS19/docker-on-nxos/vagrant directory

# Laptop bash command
vagrant ssh

! NX-OS Commands (non-privileged network admin user)
run bash

### NX-OS Linux Bash Commands

# How many vCPUs do we have
grep processor /proc/cpuinfo

# Let's watch the processes
top
```

* Session 2: SSH into the same switch and start the stress container

```bash
# Run command from DEVWKS-2096-CLUS19/docker-on-nxos/vagrant directory

# Laptop bash command
vagrant ssh

! NX-OS Commands (privileged root user, management VRF)
run bash sudo ip netns exec management bash

### NX-OS Linux Bash Commands

# Nexus 9000v only has 2 vCPUs so stress them both
docker run -it --name=stress progrium/stress --cpu 2 --timeout 20
docker rm stress

# But what about a container that will spin up 6 processes/threads?
docker run -it --name=stress progrium/stress --cpu 6 --timeout 20
docker rm stress

# See the magic config file
cat /etc/sysconfig/docker

```
