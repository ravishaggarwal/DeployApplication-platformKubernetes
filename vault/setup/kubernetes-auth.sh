#!/usr/bin/env bash
set -euo pipefail

: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${KUBE_HOST:?Set KUBE_HOST}"
: "${KUBE_CA_CERT:?Set KUBE_CA_CERT}"
: "${KUBE_TOKEN_REVIEW_JWT:?Set KUBE_TOKEN_REVIEW_JWT}"

vault auth enable kubernetes 2>/dev/null || true

vault write auth/kubernetes/config \
  token_reviewer_jwt="${KUBE_TOKEN_REVIEW_JWT}" \
  kubernetes_host="${KUBE_HOST}" \
  kubernetes_ca_cert="${KUBE_CA_CERT}"

for env in dev sit1 sit4 perf prod; do
  vault policy write "auspost-health-${env}" "vault/policies/auspost-health-${env}.hcl"
  vault write "auth/kubernetes/role/auspost-health-${env}" \
    bound_service_account_names=auspost-health \
    bound_service_account_namespaces="auspost-${env}" \
    policies="auspost-health-${env}" ttl=1h
done
