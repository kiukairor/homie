#!/bin/bash
# Bootstrap homie-app as k3s SERVER (control plane)
# Ubuntu 22.04 ARM64 — run once after VM creation
set -euo pipefail

echo "==> System update"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git curl ufw helm

echo "==> Firewall"
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 6443/tcp   # k3s API server (for agent join)
sudo ufw allow 8472/udp   # Flannel VXLAN
sudo ufw allow 10250/tcp  # kubelet
sudo ufw --force enable

echo ""
echo "==> OCI Security List — open on homie-app:"
echo "    TCP 6443, UDP 8472, TCP 10250 — source: homie-ai private IP only"
echo ""

echo "==> Installing k3s (Traefik v3, Gateway API enabled)"
# --disable=traefik removes the bundled Traefik v2
# We install Traefik v3 via Helm below for Gateway API support
curl -sfL https://get.k3s.io | sh -s - server \
  --disable=traefik \
  --flannel-backend=vxlan \
  --node-name=homie-app

sleep 15
sudo kubectl wait --for=condition=Ready node/homie-app --timeout=60s

echo "==> Configuring kubeconfig"
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown "$USER:$USER" ~/.kube/config
echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
export KUBECONFIG=~/.kube/config

echo "==> Installing Gateway API CRDs"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml

echo "==> Installing Traefik v3 (Gateway API controller)"
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik \
  --namespace traefik \
  --create-namespace \
  --set providers.kubernetesGateway.enabled=true \
  --set providers.kubernetesIngress.enabled=false \
  --set gateway.enabled=true \
  --set service.type=LoadBalancer

kubectl wait --for=condition=Available deployment/traefik \
  -n traefik --timeout=120s

echo "==> Installing cert-manager"
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
kubectl wait --for=condition=Available deployment/cert-manager \
  -n cert-manager --timeout=120s

# Enable Gateway API solver (needed for cert-manager v1.15+)
kubectl patch deployment cert-manager -n cert-manager --type=json \
  -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--enable-gateway-api"}]'

echo "==> Installing ArgoCD"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl wait --for=condition=Available deployment/argocd-server \
  -n argocd --timeout=120s

echo ""
echo "==> ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo

echo ""
echo "==> NODE JOIN TOKEN (copy for setup-vm-ai.sh):"
echo "----------------------------------------------------"
sudo cat /var/lib/rancher/k3s/server/node-token
echo "----------------------------------------------------"

echo "==> Installing anti-idle cron"
chmod +x ~/homie/scripts/anti-idle.sh
(crontab -l 2>/dev/null; echo "0 */4 * * * ~/homie/scripts/anti-idle.sh") | crontab -

echo ""
echo "==> Next steps:"
echo "  1. Run setup-vm-ai.sh on homie-ai with the token above"
echo "  2. kubectl get nodes  # verify both Ready"
echo "  3. kubectl label node homie-ai node-role.kubernetes.io/worker=worker  # cosmetic display label"
echo "  4. Create secrets — see CLAUDE.md"
echo "  5. kubectl apply -f ~/homie/argocd/application.yaml"
