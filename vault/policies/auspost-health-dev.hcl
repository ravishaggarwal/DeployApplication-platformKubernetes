path "config/data/auspost-health/dev" {
  capabilities = ["read"]
}
path "sec_kv/data/auspost-health/dev" {
  capabilities = ["read"]
}
path "pki/issue/auspost-health" {
  capabilities = ["create", "update"]
}
