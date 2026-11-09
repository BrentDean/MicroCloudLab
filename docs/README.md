# MicroCloud — Engineering Guide

[← Project overview](../README.md) · [Screenshot gallery](../screenshots/README.md)

This is the engineering side of my [three-node MicroCloud build](../README.md). The recommended reading order is **Architecture → Validation → Operations**; the guides link to one another, so you can follow the build without getting lost.

| Start here | What you'll find |
|---|---|
| [Architecture](architecture.md) | The physical/virtual topology, guest storage, management and workload networks, and the tools I used |
| [Validation results](validation.md) | What actually ran, checks that passed, and supporting evidence |
| [Operations and security](operations.md) | Ansible, version control, Ubuntu Pro, Landscape, hardware-backed SSH, and the firewall rule |
| [Deployment readiness assessment](03-deployment-readiness-assessment.md) | A sample customer-style readiness checklist illustrated with the results of this lab |
| [Ansible automation](../ansible/README.md) | The real inventory and playbooks used during the build |
| [VM provisioning scripts](../scripts/) | The Bash scripts I used to provision the second and third nodes |
| [Screenshot gallery](../screenshots/README.md) | All 11 screenshots embedded with context, grouped by build stage |

## Using the examples

The inventory, VM scripts and firewall rule show the exact network and storage layout I used. If you're building a similar lab, the useful parts are the provisioning checks and test sequence; substitute your own storage paths, interfaces and address ranges.

[Start with the architecture →](architecture.md) · [Back to project overview](../README.md)
