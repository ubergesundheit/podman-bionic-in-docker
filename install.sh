#!/bin/bash

set -e

# # Build yourself

# docker build -t podman:bionic .

# docker run --name podman -d podman:bionic

# Or use prebuilt image

docker run --name podman -d quay.io/geraldpape/podman-bionic

docker cp podman:/usr/libexec .
docker cp podman:/usr/bin/runc .
docker cp podman:/usr/bin/podman .
docker cp podman:/usr/bin/slirp4netns .

sudo mkdir -p /etc/containers
sudo curl https://raw.githubusercontent.com/projectatomic/registries/master/registries.fedora -o /etc/containers/registries.conf
sudo curl https://raw.githubusercontent.com/containers/skopeo/master/default-policy.json -o /etc/containers/policy.json

sudo mkdir -p /etc/cni/net.d
sudo curl -qsSL https://raw.githubusercontent.com/containers/libpod/master/cni/87-podman-bridge.conflist | sudo tee /etc/cni/net.d/99-loopback.conf

sudo cp -r libexec /usr/libexec
sudo cp -r runc /usr/bin/runc
sudo cp -r podman /usr/bin/podman
sudo cp -r slirp4netns /usr/bin/slirp4netns
