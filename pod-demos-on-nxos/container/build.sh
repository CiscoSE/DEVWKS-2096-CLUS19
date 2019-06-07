#!/usr/bin/env bash

# Build the two containers
docker build -t gvevsetim/demo_pod_container:1 -f Dockerfile v1
docker build -t gvevsetim/demo_pod_container:2 -f Dockerfile v2

# Push the two containers
docker push gvevsetim/demo_pod_container:1
docker push gvevsetim/demo_pod_container:2

