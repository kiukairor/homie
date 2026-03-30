# k8s — Kubernetes Manifests

All manifests are managed with [Kustomize](https://kustomize.io/). ArgoCD applies the `overlays/prod` overlay on every push to `main`.

## Structure

```
k8s/
├── base/                   Namespace + all workload manifests
│   ├── kustomization.yaml
│   ├── namespace.yaml      homie-prod namespace
│   ├── backend/            FastAPI deployment + ClusterIP service
│   ├── frontend/           Nginx/PWA deployment + ClusterIP service
│   ├── postgres/           Postgres deployment + service + PVC
│   ├── redis/              Redis deployment + service
│   └── ollama/             Ollama deployment + service + PVC + model pull Job
└── overlays/
    └── prod/               Production-specific overrides
        ├── kustomization.yaml   Image pin + base inclusion
        ├── gateway.yaml         GatewayClass + Gateway (Traefik v3 listener)
        ├── httproute.yaml       HTTP→HTTPS redirect + HTTPS routes (frontend/api)
        ├── certificate.yaml     cert-manager Certificate resource
        └── cluster-issuer.yaml  Let's Encrypt ClusterIssuer
```

## Ingress / TLS

Traffic flows via Traefik v3 using the Gateway API:

```
Internet → Traefik (LoadBalancer, port 80/443)
         → Gateway (homie-gateway) in homie-prod
         → HTTPRoute: /api/* → backend:8000
                      /webhook/* → backend:8000
                      /* → frontend:80
```

TLS is terminated at the Gateway. cert-manager watches the `cert-manager.io/cluster-issuer` annotation on the Gateway and automatically provisions/renews a Let's Encrypt certificate stored as the `homie-tls` Secret.

## Ollama Node Pinning

The Ollama Deployment uses `nodeSelector: workload: ollama`, which pins it to `homie-ai`. Apply this label once after joining the agent:

```bash
kubectl label node homie-ai workload=ollama
```

## Updating Images

Image tags are pinned in `overlays/prod/kustomization.yaml`:

```yaml
images:
  - name: ghcr.io/kiukairor/homie-backend
    newTag: latest
  - name: ghcr.io/kiukairor/homie-frontend
    newTag: latest
```

Change `latest` to a specific SHA or semver tag for immutable deploys.

## Manual Apply (without ArgoCD)

```bash
kubectl apply -k k8s/overlays/prod
```
