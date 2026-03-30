# scripts — VM Bootstrap Scripts

Manual bootstrap scripts, run once per VM after initial provisioning.
If using Terraform, these are executed automatically via cloud-init — see `terraform/cloud-init/`.

## Scripts

### `setup-vm-app.sh`

Bootstraps `homie-app` as the k3s control plane.

**Installs:**
- k3s server (SQLite backend, Flannel VXLAN)
- Gateway API CRDs (standard channel)
- Traefik v3 via Helm (Gateway API controller, LoadBalancer service)
- cert-manager
- ArgoCD

**Run on homie-app:**
```bash
bash scripts/setup-vm-app.sh
```

Prints the k3s node-join token at the end — copy it for `setup-vm-ai.sh`.

---

### `setup-vm-ai.sh`

Joins `homie-ai` to the cluster as a k3s agent (worker node), then labels it for Ollama scheduling.

**Run on homie-ai:**
```bash
bash scripts/setup-vm-ai.sh <k3s-node-token> <homie-app-private-ip>
```

After joining, label the node:
```bash
# On homie-app:
kubectl label node homie-ai workload=ollama
```

---

### `anti-idle.sh`

Generates light CPU activity to keep Oracle VMs above the 20% p95 CPU threshold.
Oracle reclaims Always Free instances that stay below this threshold for 7 days.

**Installed as a cron job by `setup-vm-app.sh` and `setup-vm-ai.sh`:**
```
0 */4 * * * ~/homie/scripts/anti-idle.sh
```

Runs every 4 hours on both VMs.

## OCI Security List Requirements

After provisioning, the OCI Security Lists must allow:

| VM | Inbound rules |
|----|---------------|
| homie-app | TCP 22, 80, 443 from 0.0.0.0/0 |
| homie-app | TCP 6443, UDP 8472, TCP 10250 from homie-ai private IP |
| homie-ai | TCP 22 from 0.0.0.0/0 |
| homie-ai | UDP 8472, TCP 10250 from homie-app private IP |

Terraform manages these automatically. For manual setup, configure them in the OCI Console.
