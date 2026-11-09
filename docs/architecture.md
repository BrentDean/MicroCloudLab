# Architecture — Three-Node MicroCloud Lab

[← Project overview](../README.md) · [Engineering guide](README.md) · [Screenshot gallery](../screenshots/README.md)

## Overview

The whole lab runs on one Debian workstation using KVM/QEMU and libvirt. I built three independent Ubuntu Server 26.04.1 LTS guests with cloud-init and kept management traffic separate from the virtual uplink presented to MicroOVN.

| Virtual node | Management IPv4 | vCPUs | RAM | Virtual disks |
|---|---|---:|---:|---|
| micro1 | 10.203.10.11 | 4 | 8 GiB | 30 GiB OS + 20 GiB local + 40 GiB Ceph |
| micro2 | 10.203.10.12 | 4 | 8 GiB | 30 GiB OS + 20 GiB local + 40 GiB Ceph |
| micro3 | 10.203.10.13 | 4 | 8 GiB | 30 GiB OS + 20 GiB local + 40 GiB Ceph |

I gave every node a dedicated OS disk, a local LXD disk and a separate MicroCeph OSD disk.

## How the parts fit together

```text
Debian workstation — KVM/QEMU + libvirt
│
├── mc-mgmt (10.203.10.0/24)
│   ├── micro1 (Ubuntu) ── LXD, MicroCeph OSD, MicroOVN ── mc-vm
│   ├── micro2 (Ubuntu) ── LXD, MicroCeph OSD, MicroOVN ── mc-test
│   └── micro3 (Ubuntu) ── LXD, MicroCeph OSD, MicroOVN ── mc-peer
│
├── mc-uplink (10.203.20.0/24) ── MicroOVN north/south access
└── shared underlying workstation storage for the virtual disks
```

**MicroCloud** coordinates the initial setup. **LXD** handles instances and clustering; **MicroCeph** provides the distributed storage layer; **MicroOVN** configures the virtual workload network. I deployed workloads on all three nodes and used LXD to check their placement.

## Provisioning

I used an Ubuntu cloud image, independent OS overlays and dedicated blank virtual data disks. Each guest had a unique cloud-init identity, static management address, and an uplink interface left unnumbered for MicroCloud.

- The [Bash provisioning scripts](../scripts/) demonstrate the checks I used to avoid overwriting an existing libvirt domain, disk or NoCloud seed.
- The [cloud-init examples](../cloud-init/example/) show the guest layout without publishing actual SSH keys or generated secrets.
- [Ansible](../ansible/README.md) checked the pre-cluster readiness conditions and exact installed software revisions.

I built the scripts around a few deliberate checks: refuse existing domains and files, confirm the cloud image and disks, and keep each guest's identity separate. Their paths and network names reflect my host.

## Storage and networking

Each guest had a 20 GiB virtual disk for local LXD storage and a separate 40 GiB virtual disk assigned to MicroCeph. At validation, Ceph reported three OSDs up and in with `HEALTH_OK`; LXD showed the `local`, `remote` and `remote-fs` pools.

The default OVN workload network used 10.200.158.0/24. Two containers on different nodes exchanged ICMP traffic; the test container and nested VM both reached external IPv4 addresses and resolved DNS. I also added a narrowly scoped host firewall rule after discovering an unintended route from the guests toward my home router.

The three virtual nodes share one physical host, so Ceph replication spans virtual members rather than independent physical machines.

[← Engineering guide](README.md) · [Next: Validation results →](validation.md) · [Project overview](../README.md)
