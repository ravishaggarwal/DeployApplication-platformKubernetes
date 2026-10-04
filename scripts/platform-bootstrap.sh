#!/usr/bin/env bash
set -euo pipefail

: "${CLUSTER_NAME:?Set CLUSTER_NAME}"
: "${AWS_REGION:?Set AWS_REGION}"

aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"

# AWS Load Balancer Controller. Terraform creates the pinned IAM policy and role.

LBC_ROLE_ARN="${LBC_ROLE_ARN:?<<Set LBC_ROLE_ARN to terraform output aws_load_balancer_controller_role_arn>>}"

helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Creating the K8 SA for the IAM role created by terraform code.This Saws-load-balancer-controller pod in kub-system
# use this controller SA to get AWS temp credentails to acces the AWS services being used by Application.
helm upgrade --install aws-load-balancer-controller \
  eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName="$CLUSTER_NAME" \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=$LBC_ROLE_ARN" \
  --version 1.14.0

# Vault Injector.
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm upgrade --install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  -f k8s/vault/vault-values.yaml

kubectl get pods -n kube-system
kubectl get pods -n vault
