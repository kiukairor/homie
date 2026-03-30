# Homie — Smart Household App

## Project Overview
Smart shopping list PWA with habit learning, pantry inference, and recipe suggestions.
Deployed on Oracle Cloud free tier via a 2-node k3s cluster + ArgoCD GitOps.

---

## Infrastructure

### VM layout (Oracle Always Free — 4 OCPUs / 24 GB total)

| VM         | OCPUs | RAM   | k3s role              | Workloads                                    |
|------------|-------|-------|-----------------------|----------------------------------------------|
| homie-app  | 2     | 12 GB | server (control plane)| FastAPI, Postgres, Redis, ingress, ArgoCD    |
| homie-ai   | 2     | 12 GB | agent (worker)        | Ollama (pinned via nodeSelector)             |

Both VMs form a single k3s cluster. Ollama is a proper k8s Deployment scheduled
exclusively on homie-ai via `nodeSelector: workload=ollama` (label applied at agent join).
All services communicate over cluster DNS — no external IPs needed internally.

---

## Stack

- **Frontend**: React PWA (Vite), served via Nginx
- **Backend**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **AI inference**: Ollama (mistral:7b or llama3.2:3b) — pod on homie-ai
- **AI fallback**: Anthropic Claude API
- **Messaging**: Telegram Bot or Meta WhatsApp Cloud API (both free)
- **Ingress**: Traefik v3 (Gateway API — GatewayClass + HTTPRoute)
- **TLS**: cert-manager + Let's Encrypt (auto-renewing Certificate resource)
- **GitOps**: ArgoCD on k3s, watching this repo
- **Container registry**: ghcr.io/kiukairor

---

## Repository Structure

```
homie/
├── CLAUDE.md
├── README.md
├── .github/
│   └── workflows/
│       └── build.yml           # build + push ARM64 images to ghcr.io
├── backend/
│   ├── Dockerfile
│   ├── requirements.txt
│   ├── main.py                 # app factory, CORS, lifespan (runs Alembic)
│   ├── db/
│   │   └── session.py          # async engine + SessionLocal + get_session
│   ├── models/
│   │   └── item.py             # SQLAlchemy Item ORM model
│   ├── routers/
│   │   └── items.py            # /api/items CRUD + Pydantic schemas
│   ├── alembic.ini
│   ├── alembic/
│   │   └── versions/
│   │       └── 0001_create_items_table.py
│   └── tests/
│       ├── conftest.py         # test app + async client fixture (SQLite)
│       ├── test_health.py
│       └── test_items.py
├── frontend/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── public/
│   │   └── manifest.json
│   └── src/
│       ├── main.jsx
│       ├── App.jsx
│       ├── api.js
│       └── components/
│           ├── AddItemForm.jsx
│           ├── ItemList.jsx
│           └── ItemRow.jsx
├── k8s/
│   ├── base/
│   │   ├── kustomization.yaml
│   │   ├── namespace.yaml
│   │   ├── backend/            deployment + service
│   │   ├── frontend/           deployment + service
│   │   ├── postgres/           deployment + service + pvc
│   │   ├── redis/              deployment + service
│   │   └── ollama/             deployment + service + pvc + pull-job
│   └── overlays/
│       └── prod/
│           ├── kustomization.yaml
│           ├── gateway.yaml        # GatewayClass + Gateway (Traefik v3)
│           ├── httproute.yaml      # HTTP→HTTPS redirect + main HTTPS routes
│           ├── certificate.yaml    # cert-manager Certificate resource
│           └── cluster-issuer.yaml # Let's Encrypt ClusterIssuer
├── argocd/
│   └── application.yaml
├── terraform/
│   ├── README.md
│   ├── main.tf                 # VMs, VCN, subnets, security lists
│   ├── variables.tf / outputs.tf / backend.conf
│   ├── terraform.tfvars.example
│   ├── modules/
│   │   ├── compute/            # OCI ARM instances
│   │   ├── network/            # VCN, subnets, security lists
│   │   └── storage/            # OCI Object Storage for Terraform state
│   └── cloud-init/
│       ├── homie-app.yaml.tpl  # k3s server + ArgoCD bootstrap
│       └── homie-ai.yaml.tpl   # k3s agent join
├── scripts/
│   ├── setup-vm-app.sh         # k3s server + Traefik v3 + ArgoCD bootstrap
│   ├── setup-vm-ai.sh          # k3s agent join
│   └── anti-idle.sh            # Cron: keep Oracle VMs above idle threshold
└── docs/
    └── superpowers/
        ├── specs/              # Phase design documents
        └── plans/              # Implementation plans
```

> **Phase 1 (backend + frontend) is fully implemented and deployed.**
> Backend: FastAPI CRUD API, SQLAlchemy async, Alembic migrations, 10 tests all passing.
> Frontend: React 18 PWA (Vite), Nginx, Dockerfile.
> CI: GitHub Actions builds linux/arm64 images and pushes to ghcr.io on every push to main.
> Both pods are deployed in the `homie-prod` namespace via ArgoCD GitOps.
> See `docs/superpowers/specs/2026-03-29-phase1-design.md` and
> `docs/superpowers/plans/2026-03-29-phase1-shopping-list.md`.
>
> **Known deployment issues (as of 2026-03-30):**
> - TLS cert pending: `kiukairor.com` is behind Cloudflare proxy; Cloudflare redirects the
>   Let's Encrypt HTTP-01 ACME challenge to HTTPS before it reaches the cluster.
>   Fix: switch to DNS-01 challenge via Cloudflare API token, or temporarily grey-cloud
>   the DNS record to let HTTP-01 through.
> - Backend fix shipped (commit 981adab): added `?ssl=false` to DATABASE_URL so asyncpg
>   doesn't attempt an SSL handshake with the unencrypted Postgres pod.

---

## GitOps Flow

```
git push → GitHub (kiukairor/homie)
    → ArgoCD detects change (polls every 3 min)
    → Applies k8s/overlays/prod via Kustomize
    → Rollout to homie-prod namespace
```

Secrets are NOT stored in Git. Create once on the cluster:
```bash
kubectl create secret generic homie-secrets \
  --from-literal=postgres-password=CHANGE_ME \
  --from-literal=anthropic-api-key=sk-ant-... \
  --from-literal=telegram-bot-token=... \
  --from-literal=telegram-webhook-secret=... \
  -n homie-prod
```

---

## Cluster Bootstrap Order

```
1. setup-vm-app.sh   → k3s server, Traefik v3 (Gateway API), cert-manager, ArgoCD
2. setup-vm-ai.sh    → k3s agent joins cluster, labelled workload=ollama
3. kubectl get nodes → verify both Ready
4. Create homie-secrets
5. kubectl apply -f argocd/application.yaml
6. ArgoCD syncs → Ollama pod scheduled on homie-ai, app pods on homie-app
7. Ollama pull-job runs → pulls mistral:7b into the PVC
```

---

## Key Commands

```bash
# Cluster status
kubectl get nodes
kubectl get pods -n homie-prod -o wide   # -o wide shows which node each pod is on

# ArgoCD
kubectl apply -f ~/homie/argocd/application.yaml
argocd app sync homie
kubectl port-forward svc/argocd-server -n argocd 8080:443  # UI access

# Logs
kubectl logs -f deploy/backend -n homie-prod
kubectl logs -f deploy/ollama -n homie-prod

# TLS cert status
kubectl get certificate,certificaterequest,order,challenge -n homie-prod

# Re-run model pull job
kubectl delete job ollama-pull-model -n homie-prod
kubectl apply -f k8s/base/ollama/pull-job.yaml

# Force ArgoCD re-sync
argocd app sync homie --force
```

---

## Oracle VM Notes

- Shape: VM.Standard.A1.Flex — 2 OCPUs, 12 GB RAM each, Ubuntu 22.04 ARM64
- **homie-app OCI Security List**: open 22, 80, 443 publicly; 6443, 8472/udp, 10250 from homie-ai private IP
- **homie-ai OCI Security List**: open 22 publicly; 8472/udp, 10250 from homie-app private IP
- Anti-idle cron on both VMs — Oracle reclaims VMs with p95 CPU < 20% over 7 days
- All images must be ARM64 — build via GitHub Actions, push to ghcr.io/kiukairor
- k3s uses SQLite by default (not etcd) — far more resilient to ungraceful shutdowns
