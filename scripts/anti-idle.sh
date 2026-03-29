#!/bin/bash
# Keep Oracle VM above idle threshold (p95 CPU < 20% triggers reclaim after 7 days)
# Cron: 0 */4 * * * ~/homie/scripts/anti-idle.sh

python3 -c "
import time
start = time.time()
n = 2
while time.time() - start < 10:
    all(n % i != 0 for i in range(2, int(n**0.5)+1))
    n += 1
" &>/dev/null

# Health check on homie-app (no-op on homie-ai)
curl -sf http://localhost:8000/api/health &>/dev/null || true

echo "$(date): anti-idle ok" >> /tmp/anti-idle.log
