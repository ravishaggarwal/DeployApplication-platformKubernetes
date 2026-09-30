#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?Usage: ./scripts/deploy.sh <environment> <version>}"
VERSION="${2:?Usage: ./scripts/deploy.sh <environment> <version>}"

helm upgrade --install auspost-health ./helm/auspost-health \
  --namespace "auspost-${ENVIRONMENT}" \
  --create-namespace \
  -f "./helm/auspost-health/values-${ENVIRONMENT}.yaml" \
  --set image.repository="jfrog.example.com/AusPostJrog/auspost-health" \
  --set image.tag="$VERSION" \
  --set ingress.annotations.'alb\.ingress\.kubernetes\.io/certificate-arn'="${ACM_CERTIFICATE_ARN:?Set ACM_CERTIFICATE_ARN}" \
  --atomic --wait --timeout 10m

kubectl rollout status deployment/auspost-health \
  -n "auspost-${ENVIRONMENT}" --timeout=10m
