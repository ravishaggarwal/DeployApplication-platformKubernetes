# PLATFORM / KUBERNETES — auspost-health-platform

## Responsibility
This repository owns application runtime/deployment configuration on Kubernetes: Helm, static manifests, Vault Agent injection, Service, ALB Ingress, HPA, PDB and environment overrides. AWS cluster creation belongs to the AWS/IaC repository.

## Layout
```text
helm/auspost-health/      deployable Helm chart
k8s/static/               static-manifest alternative
k8s/vault/                Vault Kubernetes configuration
vault/                     policies and setup examples
scripts/                   deployment/Vault-to-Helm helpers
```

## Environments
The Helm chart contains values for `dev`, `sit1`, `sit4`, `perf`, and `prod`.

## Vault integration
Application config and secrets are injected from logical paths such as:
```text
config/data/auspost-health/<env>
sec_kv/data/auspost-health/<env>
pki/issue/auspost-health
```
The Vault Agent Injector renders files beneath `/vault/secrets/`; the application entrypoint consumes them as Spring configuration/certificate material.

CPU/memory/replica policy may also live in Vault. The CD pipeline reads those values **before deployment** and creates temporary Helm overrides. A Vault sidecar cannot retroactively change an admitted Pod's `resources.requests/limits`.

## Deploy
```bash
helm upgrade --install auspost-health ./helm/auspost-health \
  --namespace auspost-dev --create-namespace \
  -f ./helm/auspost-health/values-dev.yaml \
  --set image.tag=1.0.0 --wait --timeout 10m
```
Production should use `--atomic`:
```bash
helm upgrade --install auspost-health ./helm/auspost-health \
  --namespace auspost-prod --create-namespace \
  -f ./helm/auspost-health/values-prod.yaml \
  --set image.tag=1.0.0 --atomic --wait --timeout 10m
```

## Rollout, rollback and PDB
```bash
kubectl rollout status deployment/auspost-health -n auspost-prod
kubectl rollout undo deployment/auspost-health -n auspost-prod
```
A PDB protects availability during voluntary disruptions; it does not perform rollback. Deployment revision history and Helm `--atomic` provide rollback mechanisms.

## Exposure
Ingress uses AWS Load Balancer Controller (`ingressClassName: alb`) and IP targets. Expected traffic path:
```text
myauspost.com.au -> Route53 -> AWS ALB -> Kubernetes Service -> Pod:8080
```
The Route53/ACM/EKS foundation is created by the AWS/IaC repository.
