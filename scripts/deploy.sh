#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?Usage: ./scripts/deploy.sh <environment> <version>}"
VERSION="${2:?Usage: ./scripts/deploy.sh <environment> <version>}"
APP_NAME="${APP_NAME:-auspost-health}"
JFROG_REGISTRY="${JFROG_REGISTRY:-jfrog.auspost.com}"
JFROG_PROJECT="${JFROG_PROJECT:-AusPostJrog}"
NAMESPACE="auspost-${ENVIRONMENT}"


helm upgrade --install "${APP_NAME}" ./helm/auspost-health \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "./helm/auspost-health/values-${ENVIRONMENT}.yaml" \
  --set image.repository="${JFROG_REGISTRY}/${JFROG_PROJECT}/${APP_NAME}" \
  --set image.tag="$VERSION" \
  --set ingress.annotations.'alb\.ingress\.kubernetes\.io/certificate-arn'="${ACM_CERTIFICATE_ARN:?Set ACM_CERTIFICATE_ARN}" \
  --atomic --wait --timeout 10m

kubectl rollout status deployment/"${APP_NAME}" \
  -n "${NAMESPACE}" --timeout=10m

echo "Deployment completed successfully."
