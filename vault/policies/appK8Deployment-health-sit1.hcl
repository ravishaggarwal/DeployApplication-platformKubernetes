path "config/data/app-k8-deployment-health/sit1" {
  capabilities = ["read"]
}
path "sec_kv/data/app-k8-deployment-health/sit1" {
  capabilities = ["read"]
}
path "pki/issue/app-k8-deployment-health" {
  capabilities = ["create", "update"]
}
