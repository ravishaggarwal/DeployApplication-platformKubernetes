#!/usr/bin/env bash
set -euo pipefail

vault auth enable approle 2>/dev/null || true
vault policy write jenkins-ci vault/policies/jenkins-ci.hcl

vault write auth/approle/role/jenkins-ci \
  token_policies="jenkins-ci" token_ttl=1h token_max_ttl=4h

echo "Role ID:"
vault read -field=role_id auth/approle/role/jenkins-ci/role-id
echo
echo "Generate a Secret ID separately and store it in Jenkins Credentials by using below command."
#vault write -f auth/approle/role/jenkins-ci/secret-id
#this will be used by Jenkins to get the secret/jenkins/snyk & secret/jenkins/jfrog to connect to these tenancies.
