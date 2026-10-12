path "config/data/app-k8-deployment-health/dev" {
  capabilities = ["read"]
}
path "sec_kv/data/app-k8-deployment-health/dev" {
  capabilities = ["read"]
}
path "pki/issue/app-k8-deployment-health" {
  capabilities = ["create", "update"]
}
