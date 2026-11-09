# MicroCloud — Deployment Readiness and Validation Assessment

[← Operations](operations.md) · [Engineering guide](README.md) · [Project overview](../README.md)

**Lab validation:** November 7, 2026  
**Format:** Technical readiness checklist with results from my MicroCloud build

## Purpose

I used this checklist to think through a MicroCloud proof of concept from both sides: the questions I'd ask before a deployment and the tests I'd run to prove the design works. The results are from my own three-node lab.

The [project overview](../README.md) provides the shorter story; this report is for readers interested in design decisions and the evidence behind them.

## Executive summary

I built and validated a three-node MicroCloud environment using Ubuntu Server virtual machines on KVM/libvirt. MicroCloud, LXD, and MicroOVN reported three online members; MicroCeph reported `HEALTH_OK` with all three OSDs up and in. I launched containers on two nodes and a virtual machine on the third, verified working network connectivity and outbound DNS/IPv4, and used Ansible to check the nodes' configuration.

**Outcome:** The lab passed its core cluster, storage-health, workload, networking and management checks. The fun part was moving from a diagram to a running stack I could inspect and test.

## 1. Discovery: what should the deployment accomplish?

I started with the same questions I'd ask before proposing a MicroCloud design:

| Question | Why it matters |
|---|---|
| What applications will run: VMs, containers, or both? | Determines compute, storage, image and networking requirements |
| How much CPU, RAM, and storage are needed now and after growth? | Drives node sizing and usable capacity |
| What availability and recovery targets matter? | Determines the physical failure domains, backup design, and testing required |
| What network segments, routing, DNS and ingress are available? | Shapes management and workload connectivity |
| Who will administer the nodes, and how will updates be controlled? | Sets access, security, monitoring and lifecycle expectations |
| What counts as a successful proof of concept? | Establishes measurable acceptance tests before implementation |

## 2. Readiness checklist

The readiness checks focus on the layers that matter: compute, storage, networking, access, and operations.

| Area | Readiness question | Evidence to collect |
|---|---|---|
| **Compute** | Is CPU virtualization available, and is there enough memory for the planned nodes and workloads? | CPU/KVM capabilities, guest resource plan, memory headroom |
| **Operating system** | Are the Ubuntu release and MicroCloud/LXD/MicroCeph/MicroOVN channels compatible? | Release inventory and Canonical compatibility guidance |
| **Storage** | Is the selected VM or physical disk storage correctly mounted, writable and adequately sized? Are dedicated target disks identifiable? | Mount/device inventory, capacity, ownership, disk selection review |
| **Networking** | Can members communicate over the management network? Is an appropriate uplink available? | Interface inventory, addresses, routes, peer connectivity, firewall review |
| **Access** | Can administrators access nodes securely with appropriate privileges? | SSH/authentication and privilege checks |
| **Operations** | How will versions, updates, backups, monitoring and recovery be handled? | Documented controls and planned maintenance tests |

**Disk selection:** I checked the mount, free capacity, and identity of each target disk before initialization. Each guest received a separate blank virtual disk for local LXD storage and another for MicroCeph.

## 3. Lab architecture used to test the design

| Component | Implemented example |
|---|---|
| Hypervisor | KVM/QEMU and libvirt on Debian |
| Cluster nodes | Three Ubuntu Server 26.04 LTS virtual machines |
| Per-node resources | 4 vCPUs, 8 GiB RAM |
| Per-node disks | 30 GiB OS, 20 GiB local storage, 40 GiB Ceph OSD virtual disks |
| Cluster management | Dedicated management network with static guest addresses |
| Workload networking | Separate virtual uplink connected to MicroOVN |
| Workloads | Two Ubuntu containers and one nested Ubuntu VM |
| Operations | Cloud-init, shell provisioning, Ansible, Ubuntu Pro and Landscape |

This gave me a repeatable three-node setup with enough resources to run the cluster and exercise both containers and virtual machines.

## 4. Acceptance results

| Test | Observed result | Supporting record |
|---|---|---|
| Three Ubuntu nodes provisioned | Guests booted with expected network, disk and virtualization configuration | [Architecture](architecture.md) · [Validation](validation.md) |
| Cluster membership and health | Three MicroCloud, LXD and MicroOVN members online; MicroCeph `HEALTH_OK` | [Cluster health evidence](validation.md) |
| Storage configuration | Local ZFS, Ceph and CephFS pools created; verified Ceph-backed root for first container and nested VM | [Storage and workload checks](validation.md) |
| Workload operation | Two running containers on separate virtual nodes; one running Ubuntu VM on the third | [Workload evidence](../screenshots/README.md#workload-placement) |
| Networking | Cross-node container ICMP; tested workload IPv4 egress and DNS | [Cross-node traffic](../screenshots/README.md#cross-node-traffic) · [Egress and DNS](../screenshots/README.md#ipv4-egress-and-dns) |
| Automated host readiness | Ansible pre-cluster run on all three nodes: `ok=19 changed=0 failed=0` each; version/refresh-hold audit separately passed | [Automation evidence](validation.md) |
| Ubuntu management | Ubuntu Pro attached, Landscape enabled and clients active on all three nodes; the three computers appeared online in SaaS | [Ubuntu management](operations.md) |
| Network security | Scoped nftables control blocked the tested route to the home router while preserving external IPv4 and DNS | [Security checks](operations.md) |

I captured the command results and screenshots while the lab was running on November 7, then shut the VMs down after testing.

## 5. More from the build

- [Architecture](architecture.md) — layout, virtual nodes, disks, networks and provisioning approach
- [Validation results](validation.md) — cluster health, workloads, connectivity and Ansible evidence
- [Operations and security](operations.md) — Ubuntu Pro, Landscape, access and host network protection
- [Ansible automation](../ansible/README.md) and [provisioning scripts](../scripts/)
- [Screenshot gallery](../screenshots/README.md)

## Canonical references

- [MicroCloud documentation](https://canonical.com/microcloud/docs/default/)
- [MicroCloud requirements](https://canonical.com/microcloud/docs/default/reference/requirements/)
- [MicroCloud release compatibility](https://canonical.com/microcloud/docs/default/reference/releases-snaps/)


[← Operations](operations.md) · [Next: Ansible automation →](../ansible/README.md) · [Project overview](../README.md)
