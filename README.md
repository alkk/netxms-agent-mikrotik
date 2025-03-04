# NetXMS container package for MikroTik routers

This repository contains Dockerfile for building (experimental) NetXMS container image for MikroTik routers.

Known issues (correct me if I'm wrong):

* Only folders can be mounted, not files (unlike docker). This means that you need to mount a volume to /netxms/etc and copy your configuration file there instead of mounting it directly to /netxms/etc/nxagentd.conf.
* If mount point was created manually (e.g. via sftp), it's type will be "directory" instead of "container store" - and permissions will be messed up. The only working way I've found - mount everything, start container, stop container, copy configuration file to correct place, start container.

## Minimal configuration file

```ini
LogFile={stdout} # or file name, might want to mount a volume for this
DebugLevel=0 # 0-9
MasterServers=… # list of NetXMS servers with full access
ControlServers=… # list of NetXMS servers with read+execute actions access
Servers=… # list of NetXMS servers with read-only access
```

Save it to `nxagentd.conf` and copy to your router to `etc/`.

## Running container

Enable container support on your router. See [this article](https://help.mikrotik.com/docs/display/ROS/Container) for details.
Then either change registry and pull or transfer image to your router by hand.

```mikrotik
# change registry
/container/config/set registry-url=https://ghcr.io tmpdir=usb1-part1/pull

# set RAM limit for containers, it's unlimited by default
/container/config/set ram-high=128M

# add two volumes - one for config file and one for agent's data (agent database, ID file, etc.)

/container/mounts/add name=nxagent-etc src=usb1-part1/netxms-agent/etc dst=/netxms/etc
/container/mounts/add name=nxagent-data src=usb1-part1/netxms-agent/data dst=/netxms/var/lib/netxms

# pull image from registry
/container/add remote-image=ghcr.io/alkk/netxms-agent-mikrotik:5.1.4 interface=veth1 root-dir=usb1-part1/netxms-agent/root mounts=nxagent-etc,nxagent-data start-on-boot=yes logging=yes

# or load image from file
/container/add image-file=usb1-part1/netxms-agent-mikrotik-5.1.4.tar interface=veth1 root-dir=usb1-part1/netxms-agent/root mounts=nxagent-etc,nxagent-data start-on-boot=yes logging=yes

# verify that container is imported and in stopped state
/log/print
/container/print

# start container
/container/start 0 # adjust number to match your container
/container/stop 0

# copy configuration file to correct place (`usb1-part1/netxms-agent/etc` in this example)

# start container again
/container/start 0

# verify that agent is running with correct configuration
/log/print

# (optional) disable container logging
/container/set 0 logging=no
```

### Volumes and environment variables

The container image supports the following volumes:

* `/netxms/etc` - configuration directory (agent load `nxagentd.conf` file from there)
* `/netxms/var/lib/netxms` - agent's data directory

The following environment variables are supported:

* `TZ` - timezone (default: Europe/Riga). Useful for correct timestamps in logs.

## Building image

Note: sbom and provenance should be disabled because of the bugs in the RouterOS container support (at least in v7.8).

```sh
docker buildx build --platform=linux/arm64 -t ghcr.io/alkk/netxms-agent-mikrotik:latest -t ghcr.io/alkk/netxms-agent-mikrotik:5.1.4 --sbom=false --provenance=false -o type=docker .

# push to GitHub Container Registry
docker push ghcr.io/alkk/netxms-agent-mikrotik:5.1.4
docker push ghcr.io/alkk/netxms-agent-mikrotik:latest

# or save to local file
docker save ghcr.io/alkk/netxms-agent-mikrotik:5.1.4 > netxms-agent-mikrotik-5.1.4.tar
```
