#cloud-config
# homie-app — k3s control plane bootstrap
# Rendered by Terraform templatefile()
# Logs: /var/log/cloud-init-output.log

package_update: true
package_upgrade: true
packages:
  - curl
  - git
  - ufw
  - apt-transport-https

runcmd:
  # Firewall
  - ufw allow OpenSSH
  - ufw allow 80/tcp
  - ufw allow 443/tcp
  - ufw allow 6443/tcp
  - ufw allow 8472/udp
  - ufw allow 10250/tcp
  - ufw --force enable

  # Install k3s server (Traefik disabled — we install v3 via Helm)
  - |
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${k3s_version}" sh -s - server \
      --disable=traefik \
      --flannel-backend=vxlan \
      --node-name=homie-app \
      --write-kubeconfig-mode=644

  # Wait for k3s to be ready
  - until kubectl get nodes | grep -q Ready; do sleep 5; done

  # Expose kubeconfig for ubuntu user
  - mkdir -p /home/ubuntu/.kube
  - cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
  - sed -i "s/127.0.0.1/$(curl -s ifconfig.me)/g" /home/ubuntu/.kube/config
  - chown -R ubuntu:ubuntu /home/ubuntu/.kube

  # Install Helm
  - curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

  # Gateway API CRDs
  - kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml

  # Traefik v3 via Helm
  - helm repo add traefik https://helm.traefik.io/traefik
  - helm repo update
  - |
    helm install traefik traefik/traefik \
      --namespace traefik \
      --create-namespace \
      --set providers.kubernetesGateway.enabled=true \
      --set providers.kubernetesIngress.enabled=false \
      --set service.type=LoadBalancer \
      --wait

  # cert-manager
  - kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
  - kubectl wait --for=condition=Available deployment/cert-manager -n cert-manager --timeout=120s

  # ArgoCD
  - kubectl create namespace argocd
  - kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  - kubectl wait --for=condition=Available deployment/argocd-server -n argocd --timeout=180s

  # Anti-idle cron
  - |
    echo "0 */4 * * * python3 -c \"import time; start=time.time(); n=2; [all(n%i!=0 for i in range(2,int(n**0.5)+1)) or None for n in range(2,99999) if time.time()-start<10]\" &>/dev/null" | crontab -u ubuntu -

  # Signal done
  - touch /var/lib/cloud/instance/homie-app-ready
  - echo "homie-app cloud-init complete" >> /var/log/homie-init.log
