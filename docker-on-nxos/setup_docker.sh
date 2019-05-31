#!/usr/bin/env bash
###
### Assumption - python3 is in path via activatation 
### of DEVBOX virtual environment
###
###   source ~/venv/bin/activate
###

# DEVNET Sandbox Nexus 9000v mgmt0 addresses are:
# 172.16.30.101-104

for i in $(seq 1 4); do \
    echo "Node nx-os9000v-${i}"; \
    python3 config_docker.py -t 172.16.30.10${i}; \
done

