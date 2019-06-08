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

