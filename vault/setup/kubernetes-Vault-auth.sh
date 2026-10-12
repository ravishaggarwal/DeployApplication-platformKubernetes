#!/usr/bin/env bash

set -euo pipefail


: "${VAULT_ADDR:?Set VAULT_ADDR}"
: "${EKS_CLUSTER_NAME:?Set EKS_CLUSTER_NAME}"

AWS_REGION="${AWS_REGION:-ap-southeast-2}"

VAULT_AUTH_PATH="${VAULT_AUTH_PATH:-kubernetes}"

APP_NAME="app-k8-deployment-health"


echo "Using Enterprise Vault:"
echo "${VAULT_ADDR}"


echo "Getting EKS API endpoint..."

KUBE_HOST="$(
    aws eks describe-cluster \
        --name "${EKS_CLUSTER_NAME}" \
        --region "${AWS_REGION}" \
        --query 'cluster.endpoint' \
        --output text
)"


echo "Getting Kubernetes CA..."

KUBE_CA_DATA="$(
    aws eks describe-cluster \
        --name "${EKS_CLUSTER_NAME}" \
        --region "${AWS_REGION}" \
        --query 'cluster.certificateAuthority.data' \
        --output text
)"


KUBE_CA_FILE="$(mktemp)"

trap 'rm -f "${KUBE_CA_FILE}"' EXIT


printf '%s' "${KUBE_CA_DATA}" |
    base64 --decode > "${KUBE_CA_FILE}"


echo "Enabling Kubernetes auth if required..."

if ! vault auth list -format=json |
    jq -e \
    --arg path "${VAULT_AUTH_PATH}/" \
    'has($path)' >/dev/null
then

    vault auth enable \
        -path="${VAULT_AUTH_PATH}" \
        kubernetes

fi


echo "Configuring Kubernetes authentication..."

vault write \
    "auth/${VAULT_AUTH_PATH}/config" \
    kubernetes_host="${KUBE_HOST}" \
    kubernetes_ca_cert=@"${KUBE_CA_FILE}" \
    disable_local_ca_jwt=true


for env in dev sit1 sit4 perf prod
do

    NAMESPACE="appK8Deployment-${env}"
    POLICY="${APP_NAME}-${env}"
    ROLE="${APP_NAME}-${env}"
    
    echo "Configuring ${env}..."

    kubectl create namespace "${NAMESPACE}" \
        --dry-run=client \
        -o yaml |
        kubectl apply -f -


    kubectl create serviceaccount "${APP_NAME}" \
        --namespace "${NAMESPACE}" \
        --dry-run=client \
        -o yaml |
        kubectl apply -f -


    kubectl create clusterrolebinding \
        "${APP_NAME}-${env}-auth-delegator" \
        --clusterrole=system:auth-delegator \
        --serviceaccount="${NAMESPACE}:${APP_NAME}" \
        --dry-run=client \
        -o yaml |
        kubectl apply -f -


    vault policy write \
        "${POLICY}" \
        "vault/policies/${POLICY}.hcl"


    vault write \
        "auth/${VAULT_AUTH_PATH}/role/${ROLE}" \
        bound_service_account_names="${APP_NAME}" \
        bound_service_account_namespaces="${NAMESPACE}" \
        policies="${POLICY}" \
        ttl="1h"

done


echo "Vault Kubernetes authentication configured."