#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?Usage: ./scripts/deploy.sh <environment> <version>}"
VERSION="${2:?Usage: ./scripts/deploy.sh <environment> <version>}"
APP_NAME="${APP_NAME:-app-k8-deployment-health}"
JFROG_REGISTRY="${JFROG_REGISTRY:-jfrog.appK8Deployment.com}"
JFROG_PROJECT="${JFROG_PROJECT:-appK8DeploymentJrog}"
NAMESPACE="appK8Deployment-${ENVIRONMENT}"


helm upgrade --install "${APP_NAME}" ./helm/app-k8-deployment-health \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "./helm/app-k8-deployment-health/values-${ENVIRONMENT}.yaml" \
  --set image.repository="${JFROG_REGISTRY}/${JFROG_PROJECT}/${APP_NAME}" \
  --set image.tag="$VERSION" \
  --set ingress.annotations.'alb\.ingress\.kubernetes\.io/certificate-arn'="${ACM_CERTIFICATE_ARN:?Set ACM_CERTIFICATE_ARN}" \
  --atomic --wait --timeout 10m

kubectl rollout status deployment/"${APP_NAME}" \
  -n "${NAMESPACE}" --timeout=10m

echo "Deployment completed successfully."
