#!/usr/bin/env

# Note: purpose of this script is simply to test each version

# Test run each container on a generic Docker host
docker run -d --name=demo_pod_1 -p 127.0.0.1:11234:1234 gvevsetim/demo_pod_container:1
docker run -d --name=demo_pod_2 -p 127.0.0.1:21234:1234 gvevsetim/demo_pod_container:2

