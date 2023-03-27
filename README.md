# NetXMS container package for MikroTik routers

This repository contains Dockerfile for building (experimental) NetXMS container image for MikroTik routers.

## Minimal configuration file

```ini
LogFile={stdout} # or file name, might want to mount a volume for this
DebugLevel=0 # 0-9
MasterServers=… # list of NetXMS servers with full access
ControlServers=… # list of NetXMS servers with read+execute actions access
Servers=… # list of NetXMS servers with read-only access
```

Save as a file and copy to your router.

## Running container

Enable container support on your router. See [this article](https://help.mikrotik.com/docs/display/ROS/Container) for details.
Then either change registry and pull or transfer image to your router by hand.

```mikrotik
# change registry
/container/config/set registry-url=https://ghcr.io tmpdir=usb1-part1/pull

# add two volumes - one for config file and one for agent's data (agent database, ID file, etc.)

/container/mounts/add name=nxagent-config src=usb1-part1/netxms-agent/nxagentd.conf dst=/netxms/etc/nxagentd.conf
/container/mounts/add name=nxagent-data src=usb1-part1/netxms-agent/data dst=/netxms/var/lib/netxms

# pull image from registry
/container/add remote-image=ghcr.io/alkk/netxms-agent-mikrotik:4.3.2 interface=veth1 root-dir=usb1-part1/netxms-agent/root mounts=nxagent-config,nxagent-data start-on-boot=yes logging=no

# or load image from file
/container/add image-file=usb1-part1/netxms-agent-mikrotik-4.3.2.tar interface=veth1 root-dir=usb1-part1/netxms-agent/root mounts=nxagent-config,nxagent-data start-on-boot=yes logging=no

# verify that container is imported and in stopped state
/container/print

# start container
/container/start number=0 # adjust number to match your container
```

### Volumes and environment variables

The container image supports the following volumes:

* `/netxms/etc` - configuration directory (agent load `nxagentd.conf` file)
* `/netxms/var/lib/netxms` - agent's data directory

The following environment variables are supported:

* `TZ` - timezone (default: Europe/Riga). Useful for correct timestamps in logs.

## Building image

Note: sbom and provenance should be disabled because of the bugs in the RouterOS container support (at least in v7.8).

```sh
docker buildx build --platform=linux/arm64 -t ghcr.io/alkk/netxms-agent-mikrotik:latest -t ghcr.io/alkk/netxms-agent-mikrotik:4.3.2 --sbom=false --provenance=false -o type=docker .

# push to GitHub Container Registry
docker push ghcr.io/alkk/netxms-agent-mikrotik:4.3.2
docker push ghcr.io/alkk/netxms-agent-mikrotik:latest

# or save to local file
docker save ghcr.io/alkk/netxms-agent-mikrotik:4.3.2 > netxms-agent-mikrotik-4.3.2.tar
```
