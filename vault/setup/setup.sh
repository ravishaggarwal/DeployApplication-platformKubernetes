#!/usr/bin/env bash
set -euo pipefail

vault secrets enable -path=config kv-v2 2>/dev/null || true
vault secrets enable -path=sec_kv kv-v2 2>/dev/null || true
vault secrets enable -path=secret kv-v2 2>/dev/null || true

for env in dev sit1 sit4 perf prod; do
  case "$env" in
    dev)  CPU_REQUEST=100m; MEMORY_REQUEST=256Mi; CPU_LIMIT=500m; MEMORY_LIMIT=512Mi; MIN_REPLICAS=2; MAX_REPLICAS=3 ;;
    sit1) CPU_REQUEST=150m; MEMORY_REQUEST=256Mi; CPU_LIMIT=500m; MEMORY_LIMIT=512Mi; MIN_REPLICAS=2; MAX_REPLICAS=4 ;;
    sit4) CPU_REQUEST=200m; MEMORY_REQUEST=384Mi; CPU_LIMIT=500m; MEMORY_LIMIT=512Mi; MIN_REPLICAS=2; MAX_REPLICAS=4 ;;
    perf) CPU_REQUEST=500m; MEMORY_REQUEST=512Mi; CPU_LIMIT=1; MEMORY_LIMIT=1Gi; MIN_REPLICAS=3; MAX_REPLICAS=8 ;;
    prod) CPU_REQUEST=500m; MEMORY_REQUEST=512Mi; CPU_LIMIT=1; MEMORY_LIMIT=1Gi; MIN_REPLICAS=3; MAX_REPLICAS=10 ;;
  esac

  vault kv put "config/auspost-health/${env}" \
    APP_MESSAGE="AusPost ${env} environment" \
    APP_FEATURE_FLAG="true" \
    CPU_REQUEST="$CPU_REQUEST" MEMORY_REQUEST="$MEMORY_REQUEST" \
    CPU_LIMIT="$CPU_LIMIT" MEMORY_LIMIT="$MEMORY_LIMIT" \
    MIN_REPLICAS="$MIN_REPLICAS" MAX_REPLICAS="$MAX_REPLICAS"

  vault kv put "sec_kv/auspost-health/${env}" \
    API_CLIENT_ID="replace-in-vault" \
    API_CLIENT_SECRET="replace-in-vault"
done

# PKI example. Replace with your enterprise CA/signing model for production.
vault secrets enable pki 2>/dev/null || true
vault secrets tune -max-lease-ttl=8760h pki
vault write pki/root/generate/internal \
  common_name="AusPost Example Root CA" ttl=8760h >/dev/null 2>&1 || true
vault write pki/roles/auspost-health \
  allowed_domains="myauspost.com.au" \
  allow_subdomains=false \
  max_ttl="24h" ttl="24h" >/dev/null 2>&1 || true

echo "Store CI secrets in Vault, for example:"
echo 'vault kv put secret/jenkins/snyk token="..."'
echo 'vault kv put secret/jenkins/jfrog username="..." password="..."'
echo 'vault kv put secret/jenkins/sonarqube token="..."'
