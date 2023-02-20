# Aks Hybrid bootcamp

This bootcamp will explain what aks hybrid is focusing on the design and architecture of aks hybrid solutions, as part of this bootcamp the following topics will be covered:

1. [Creation of aks host](00-aks-host/script.ps)
2. [Creation of aks workload cluster](01-new-workload-cluster/script.ps)
3. [Connecting to workload cluster](02-kubectl-to-cluster/script.ps)
4. [Deploy aks app](03-deploy-app/script.ps)
5. [Configure azure ad authentication](04-azure-ad/script.ps)
6. [Configure azure RBAC](05-azure-rbac/script.ps)
7. [Configure monitoring](06-monitoring/script.ps)
8. [Provision ARC resource bridge](07-resource-bridge/script.ps)
9. [Patching and upgrade](08-patching-and-upgrade/script.ps)
10. [Autoscaler](09-autoscaler/script.ps)

## Duration

This bootcamp will have a duration of **5 hours**, during this time it will not be possible to cover all the scenarios described, it is expected that attendants will try some of them at their own pace.

## Audience

This bootcamp is targeted to the following roles

- Azure Stack HCI infrastructure engineer looking to understand better what Kubernetes is and what administrative/operational tasks are needed in the Stack HCI environment
- Kubernetes / AKS Admin looking at understanding aks hybrid solution and differences between aks hybrid and other K8s distribution (cloud based or on-premises)

## Environment

- We will use a Windows Server nested virtualization environment installed following the instructions from: https://learn.microsoft.com/en-us/azure/aks/hybrid/aks-hci-evaluation-guide-1
 - Make sure you select Premium SSD for disks and 256GB disk size
 - You can turn off the VM after creation and start it for the bootcamp
- Install az cli in the vm
