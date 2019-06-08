# Setting up Docker on NX-OS

## Prerequisites

* NX-OS version 9.2(1) or newer
  * Nexus 9000 switches with >8GB RAM
  * Nexus 9000v virtual switch
  * Either: HTTP support enabled (preferred)
  * Or: Supported CA signed SSL certificate
* DEVNET Sandbox “Open NX-OS with Nexus 9Kv Lab” Reservation
* VPN Connection into the Sandbox

## Installation

* (On Nexus switch) Enable HTTP tcp/80 (if needed)

```cisco
! Enter config mode
configure terminal
!
! Enable HTTP NXAPI Support
nxapi http port 80
!
! Exit
end
```

* (On server) Activate Python 3.6 (or newer) virtual environment

```python
python3 config_docker.py -t NXOS_MGMT_IP
```

## Demonstrate CPU protections

The above script places the Docker daemon into the /ext_ser/ cgroup
that contains CPU usage to 40% (per core).  This demo will simply
demonstrate that the CPU load is properly capped.

* Session 1: SSH into a switch and run top

```bash
ssh admin@172.16.30.101
top
```

* Session 2: SSH into the same switch and start the stress container

```bash
ssh admin@172.16.30.101

# Nexus 9000v only has 2 vCPUs so stress them both
docker run -it --name=stress progrium/stress --cpu 2 --timeout 20
docker rm stress

# But what about a container that will spin up 6 processes/threads?
docker run -it --name=stress progrium/stress --cpu 6 --timeout 20
docker rm stress
```
