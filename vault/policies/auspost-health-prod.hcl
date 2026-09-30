path "config/data/auspost-health/prod" {
  capabilities = ["read"]
}
path "sec_kv/data/auspost-health/prod" {
  capabilities = ["read"]
}
path "pki/issue/auspost-health" {
  capabilities = ["create", "update"]
}
