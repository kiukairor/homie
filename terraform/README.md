# Terraform — Homie Infrastructure

## Overview
Provisions two OCI ARM VMs, VCN, subnets, security lists, and object storage for Terraform state.
Bootstraps k3s cluster via cloud-init and applies the ArgoCD Application manifest.

## Prerequisites
- Terraform >= 1.6
- OCI account with Always Free tier
- OCI CLI configured (`~/.oci/config`)
- SSH key pair

## First-Time Setup

### Step 1 — Bootstrap state bucket
The OCI Object Storage backend requires the bucket to exist before `terraform init` can use it.
On first run, comment out the `backend "s3"` block in `main.tf`, then:

```bash
cp terraform.tfvars.example terraform.tfvars
# fill in terraform.tfvars

terraform init
terraform apply -target=module.storage
```

### Step 2 — Migrate state to OCI bucket
Uncomment the `backend "s3"` block, then:

```bash
terraform init -migrate-state
```

### Step 3 — Apply everything
```bash
terraform apply
```

This provisions:
- VCN, subnet, security lists
- homie-app VM (cloud-init bootstraps k3s server + ArgoCD)
- homie-ai VM (cloud-init joins k3s cluster as agent)

---

## The Token Bootstrap Problem

k3s agent nodes need a join token from the control plane to join the cluster.
This is a classic chicken-and-egg: the token doesn't exist until the VM boots.

**How it's handled here — two-phase apply:**

**Phase 1** (automated): Terraform creates both VMs. homie-ai cloud-init waits
for the k3s API to be reachable, then tries to fetch the token over the private
network. homie-app serves the token on a temporary HTTP endpoint (port 9999)
during cloud-init only, closed after join.

**Alternative (simpler but manual)**: Apply homie-app first, SSH in and grab
the token, then pass it as a Terraform variable for homie-ai:

```bash
terraform apply -target=module.compute.oci_core_instance.homie_app
ssh ubuntu@<app_public_ip> "sudo cat /var/lib/rancher/k3s/server/node-token"
# add token to terraform.tfvars as k3s_node_token
terraform apply
```

---

## After Apply

1. Check cloud-init logs on each VM:
   ```bash
   ssh ubuntu@<app_public_ip> "tail -f /var/log/cloud-init-output.log"
   ssh ubuntu@<ai_public_ip>  "tail -f /var/log/cloud-init-output.log"
   ```

2. Verify cluster:
   ```bash
   ssh ubuntu@<app_public_ip> "kubectl get nodes"
   # Should show homie-app (control-plane) and homie-ai (worker) as Ready
   ```

3. Create k8s secrets (not managed by Terraform — kept out of state):
   ```bash
   ssh ubuntu@<app_public_ip>
   kubectl create secret generic homie-secrets \
     --from-literal=postgres-password=CHANGE_ME \
     --from-literal=anthropic-api-key=sk-ant-... \
     --from-literal=telegram-bot-token=... \
     --from-literal=telegram-webhook-secret=... \
     -n homie-prod
   ```

4. Point your domain A record at the `app_public_ip` output value

5. ArgoCD will sync automatically — check:
   ```bash
   ssh ubuntu@<app_public_ip> "kubectl get applications -n argocd"
   ```

---

## Teardown
```bash
terraform destroy
```
Note: the tfstate bucket has versioning enabled — destroy will fail on non-empty buckets.
Empty it first in the OCI Console or via OCI CLI.
