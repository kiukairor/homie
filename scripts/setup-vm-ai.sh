#!/bin/bash
# Bootstrap homie-ai as k3s AGENT (worker node)
# Ubuntu 22.04 ARM64 — run after setup-vm-app.sh completes
# Run as: K3S_TOKEN=<token> CONTROL_PLANE_IP=<ip> bash scripts/setup-vm-ai.sh
set -euo pipefail

: "${K3S_TOKEN:?Set K3S_TOKEN to the token from setup-vm-app.sh}"
: "${CONTROL_PLANE_IP:?Set CONTROL_PLANE_IP to homie-app private IP}"

echo "==> System update"
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y curl ufw

echo "==> Firewall (worker node)"
sudo ufw allow OpenSSH
sudo ufw allow 8472/udp   # Flannel VXLAN
sudo ufw allow 10250/tcp  # kubelet
sudo ufw --force enable

echo ""
echo "==> Also open in OCI Security List for homie-ai:"
echo "    UDP 8472  — source: homie-app private IP"
echo "    TCP 10250 — source: homie-app private IP"
echo ""

echo "==> Joining k3s cluster as agent"
curl -sfL https://get.k3s.io | sh -s - agent \
  --server "https://${CONTROL_PLANE_IP}:6443" \
  --token "${K3S_TOKEN}" \
  --node-name=homie-ai \
  --node-label="workload=ollama"

echo "==> Installing anti-idle cron"
chmod +x ~/homie/scripts/anti-idle.sh
(crontab -l 2>/dev/null; echo "0 */4 * * * ~/homie/scripts/anti-idle.sh") | crontab -

echo ""
echo "==> homie-ai joined the cluster."
echo "    Verify on homie-app: kubectl get nodes"
echo "    Should show homie-ai as Ready worker."
echo ""
echo "    ArgoCD will schedule Ollama pod here automatically"
echo "    via nodeSelector: workload=ollama"
