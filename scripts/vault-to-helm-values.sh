#!/usr/bin/env bash
set -euo pipefail

: "${VAULT_TOKEN:?Set VAULT_TOKEN}"
: "${VAULT_ENVIRONMENT:?Set VAULT_ENVIRONMENT}"
: "${VAULT_ADDR:?Set VAULT_ADDR}"

vault kv get -format=json "config/auspost-health/${VAULT_ENVIRONMENT}" > /tmp/auspost-vault-config.json

jq -r '.data.data |
  "resources:\n" +
  "  requests:\n" +
  "    cpu: " + (.CPU_REQUEST // "100m") + "\n" +
  "    memory: " + (.MEMORY_REQUEST // "256Mi") + "\n" +
  "  limits:\n" +
  "    cpu: " + (.CPU_LIMIT // "500m") + "\n" +
  "    memory: " + (.MEMORY_LIMIT // "512Mi") + "\n" +
  "autoscaling:\n" +
  "  minReplicas: " + (.MIN_REPLICAS // "2") + "\n" +
  "  maxReplicas: " + (.MAX_REPLICAS // "4")'   /tmp/auspost-vault-config.json > /tmp/vault-values.yaml

cat /tmp/vault-values.yaml
