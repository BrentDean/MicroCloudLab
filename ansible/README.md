# Ansible — MicroCloud Lab Automation

[← Operations](../docs/operations.md) · [Engineering guide](../docs/README.md) · [Screenshot gallery](../screenshots/README.md)

This is the Ansible setup I used to get three Ubuntu nodes into a predictable state: verify connectivity and prerequisites, check exact MicroCloud snap revisions, then enroll the nodes in Ubuntu Pro and Landscape.

## Playbooks

| File | Purpose | Status in this project |
|---|---|---|
| [01-preflight.yml](playbooks/01-preflight.yml) | Inspect Ubuntu, management network, untouched data disks, KVM, time, Internet, Snap Store and peer reachability | Passed **before** cluster initialization |
| [02-snaps.yml](playbooks/02-snaps.yml) | Verify expected snap versions, channels, cohorts and holds; install missing snaps only when approved | Verified no-change state on three nodes |
| [03-pro-landscape.yml](playbooks/03-pro-landscape.yml) | Attach Ubuntu Pro if needed and onboard Landscape using secrets held outside Git | Enrollment verified on all three nodes |
| [site.yml](site.yml) | Imports the **original pre-cluster** preflight and snap playbooks | **Do not rerun on initialized storage** |

**Important:** `site.yml` includes a pre-cluster check that expects blank `/dev/vdb` and `/dev/vdc` disks. Run it only **before** initializing MicroCloud storage. For an existing cluster, use the standalone snap-state playbook to inspect revision drift.

## Recorded results

- Initial Ansible connection checks and sudo succeeded on all three Ubuntu VMs.
- Pre-cluster preflight: **`ok=19 changed=0 unreachable=0 failed=0`** for each node.
- Snap revision checks: **`ok=10 changed=0 unreachable=0 failed=0`** per node; all four components matched the approved November 7 revision baseline and reported `in-cohort,held`.
- Ubuntu Pro and Landscape: all three nodes reported the Landscape client `active` and Pro attached; the three computers appeared online in Landscape SaaS.

The [three-node preflight evidence](../screenshots/README.md#ansible-preflight) and the [Ubuntu Pro/Landscape enrollment evidence](../screenshots/README.md#ubuntu-pro-and-landscape-onboarding) are together in the screenshot gallery.

## Configuration

The [inventory](inventory/hosts.yml) lists the nodes on my `10.203.10.0/24` management network. The [group variables](inventory/group_vars/microcloud_nodes.yml) capture the verified snap revisions; SSH private-key locations are kept outside this repository.

If your SSH key is not available through your SSH agent or SSH configuration, set its local path before running Ansible:

```bash
export ANSIBLE_PRIVATE_KEY_FILE="/path/to/your/ssh_private_key"
```

The host provisioning scripts under `scripts/` also accept paths at runtime rather than embedding workstation directories:

```bash
export MICROCLOUD_LAB_ROOT="/path/to/microcloud-data"
export MICROCLOUD_SSH_PUBKEY_1="/path/to/first_key.pub"
export MICROCLOUD_SSH_PUBKEY_2="/path/to/second_key.pub"
# micro3 only: backing mountpoint must be ext4.
export MICROCLOUD_STORAGE_MOUNT="/path/to/ext4-mountpoint"
```

These are examples of configurable paths, not live values. No private SSH keys or storage mount locations should be committed.

My tested combination was Ubuntu 26.04.1, MicroCloud 3.4.1, LXD 6.10.1, MicroCeph 20.2.1 and MicroOVN 26.03. For another cluster, I'd compare the release channels with [Canonical's compatibility matrix](https://canonical.com/microcloud/docs/default/reference/releases-snaps/) before using the same pins.

The [Pro/Landscape playbook](playbooks/03-pro-landscape.yml) reads `ubuntu_pro_token` and `landscape_account_name` from an external encrypted Ansible Vault file. It avoids logging the token and cleans up its temporary attachment file when finished.

## Safe inspection

Read the inventory and playbooks before running anything. A static syntax check is safe; it does not deploy or change a cluster:

```bash
cd ansible
ansible-playbook --syntax-check site.yml
ansible-playbook --syntax-check playbooks/03-pro-landscape.yml
```

[← Operations](../docs/operations.md) · [View the screenshot gallery →](../screenshots/README.md) · [Project overview](../README.md)
