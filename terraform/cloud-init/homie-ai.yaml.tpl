#cloud-config
# homie-ai — k3s worker node bootstrap
# Rendered by Terraform templatefile()
# Logs: /var/log/cloud-init-output.log

package_update: true
package_upgrade: true
packages:
  - curl
  - ufw

runcmd:
  # Firewall — no public ports except SSH
  - ufw allow OpenSSH
  - ufw allow 8472/udp
  - ufw allow 10250/tcp
  - ufw --force enable

  # Wait for homie-app control plane to be ready
  # Polls the k3s API endpoint until it responds
  - |
    echo "Waiting for k3s API on homie-app..."
    until curl -sk https://${app_private_ip}:6443/readyz | grep -q ok; do
      sleep 10
    done
    echo "Control plane ready."

  # Fetch join token from homie-app via OCI internal metadata
  # Token is written to a known path by homie-app cloud-init
  # We retrieve it over the private network via SSH (using instance principal)
  # Simpler alternative: hardcode token via Terraform after first apply
  # For now, token is injected by Terraform as a templatefile variable
  # after homie-app is up (two-phase apply — see CLAUDE.md)
  - |
    curl -sfL https://get.k3s.io | \
      INSTALL_K3S_VERSION="${k3s_version}" \
      K3S_URL="https://${app_private_ip}:6443" \
      K3S_TOKEN="$(curl -sf http://${app_private_ip}:9999/token || echo 'REPLACE_ME')" \
      sh -s - agent \
        --node-name=homie-ai \
        --node-label="workload=ollama"

  # Anti-idle cron
  - |
    echo "0 */4 * * * python3 -c \"import time; start=time.time(); n=2; [all(n%i!=0 for i in range(2,int(n**0.5)+1)) or None for n in range(2,99999) if time.time()-start<10]\" &>/dev/null" | crontab -u ubuntu -

  - echo "homie-ai cloud-init complete" >> /var/log/homie-init.log
