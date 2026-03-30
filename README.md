# Homie

Smart household shopping list PWA with habit learning, pantry inference, and recipe suggestions.
Deployed on Oracle Cloud free tier via a 2-node k3s cluster + ArgoCD GitOps.

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 0 | Infrastructure (k3s cluster, Terraform, GitOps) | Done |
| Phase 1 | Shopping list CRUD API + React PWA | Planned |
| Phase 2 | AI agent (Ollama / Claude) | Planned |
| Phase 3 | Telegram / WhatsApp bot | Planned |

## Stack

- **Frontend**: React PWA (Vite), served via Nginx
- **Backend**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **AI inference**: Ollama (mistral:7b or llama3.2:3b) on dedicated worker node
- **AI fallback**: Anthropic Claude API
- **Ingress**: Traefik v3 with Gateway API (GatewayClass + HTTPRoute)
- **TLS**: cert-manager + Let's Encrypt
- **GitOps**: ArgoCD watching this repo
- **Registry**: ghcr.io/kiukairor
- **Infrastructure**: Oracle Cloud Always Free — 2× VM.Standard.A1.Flex (ARM64)

## Repository Layout

```
homie/
├── k8s/          Kubernetes manifests (Kustomize base + prod overlay)
├── argocd/       ArgoCD Application manifest
├── terraform/    OCI infrastructure — VMs, VCN, security lists
├── scripts/      Manual bootstrap scripts (run once per VM)
└── docs/         Phase specs and implementation plans
```

## Quick Start

See [`terraform/README.md`](terraform/README.md) to provision the cluster from scratch.

For manual VM setup without Terraform, run the scripts in order:

```bash
# On homie-app
bash scripts/setup-vm-app.sh

# On homie-ai (with token printed by above)
bash scripts/setup-vm-ai.sh <k3s-node-token> <homie-app-private-ip>
```

Once both nodes are `Ready`, create the cluster secret and apply the ArgoCD app:

```bash
kubectl create secret generic homie-secrets \
  --from-literal=postgres-password=CHANGE_ME \
  --from-literal=anthropic-api-key=sk-ant-... \
  --from-literal=telegram-bot-token=... \
  --from-literal=telegram-webhook-secret=... \
  -n homie-prod

kubectl apply -f argocd/application.yaml
```

ArgoCD will sync and deploy everything to the `homie-prod` namespace.

## Secrets

Secrets are **not** stored in Git. They are created once on the cluster (see above).
The `homie-secrets` Secret is referenced by the backend Deployment via `secretKeyRef`.

## Domain Setup

Point the `kiukairor.com` A record at the `homie-app` public IP (from `terraform output app_public_ip`).

Still needs your email in `k8s/overlays/prod/cluster-issuer.yaml` (the `email:` field for Let's Encrypt registration).

Commit and push — ArgoCD will apply the changes and cert-manager will issue the TLS certificate.

## Oracle VM Notes

- Shape: VM.Standard.A1.Flex — 2 OCPUs, 12 GB RAM, Ubuntu 22.04 ARM64 (each)
- All images must be `linux/arm64` — built via GitHub Actions QEMU + buildx
- Anti-idle cron keeps VMs above Oracle's 20% p95 CPU threshold (reclaim protection)
- k3s uses SQLite (not etcd) — resilient to ungraceful shutdowns
