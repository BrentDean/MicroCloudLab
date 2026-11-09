# Operations, Security and Ubuntu Management

[← Validation](validation.md) · [Engineering guide](README.md) · [Screenshot gallery](../screenshots/README.md)

## Automation

I used Ansible to confirm that all three Ubuntu nodes could be reached and that their hostnames, time synchronization, management interfaces, nested KVM access, and software revisions were consistent.

The [Ansible inventory and playbooks](../ansible/README.md) show how I checked the nodes before initialization and verified snap revisions. The blank-disk preflight belongs **before** MicroCloud sets up storage; the separate snap-state playbook is useful for checking revision drift afterward.

I pinned compatible MicroCloud component revisions and set refresh holds so I could debug a stable cluster instead of chasing version changes.

## Ubuntu Pro and Landscape

Once the cluster was running, I used a separate Ansible playbook to attach Ubuntu Pro and request Landscape onboarding. The [enrollment screenshot in the gallery](../screenshots/README.md#ubuntu-pro-and-landscape-onboarding) captures the successful `micro1` run (`ok=17 changed=5 failed=0`), including the active Landscape client.

- `pro status` confirmed attached Ubuntu Pro subscriptions and enabled Landscape integration on micro1, micro2 and micro3.
- `systemctl is-active landscape-client` returned `active` on all three.
- Landscape SaaS showed all three computers online.

The onboarding playbook uses an external encrypted Ansible Vault file for credentials, creates a temporary root-only attach configuration, and removes it afterward. I kept the cluster's snap update policy under explicit control.

## Access

I used YubiKey-backed SSH to log into the Ubuntu nodes. The [cloud-init example](../cloud-init/example/user-data) shows how I configured SSH access with a public-key placeholder; the actual hardware-backed keys stay on my workstation. I also used passwordless sudo in the lab to simplify repeated provisioning and administration.

## Network isolation

During testing I found that virtual guests could reach a path toward the home router. I added a small, dedicated `nftables` FORWARD rule for the lab bridges and a systemd oneshot service to manage **only** its own table. I tested the negative path, then verified that external IPv4 access and DNS still worked.

The [nftables rule](../config/mc-lan-guard.nft) uses the bridge names and subnet from my lab. I kept it in a dedicated table so I could adjust that policy without disturbing the other network services on the workstation.

## What I learned

The most useful part was moving between the layers: guest provisioning, the underlying libvirt networks, cluster services, LXD workloads, and host-level firewall behavior. A successful `microcloud init` isn't the end of an infrastructure test; the workload and management checks are what showed me the system was actually usable.

[← Validation results](validation.md) · [Next: Deployment readiness assessment →](03-deployment-readiness-assessment.md) · [Project overview](../README.md)
