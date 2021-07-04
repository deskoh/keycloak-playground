#!/bin/bash
# Exit on error
set -e

# Example script for Keycloak configuration
# Assumes kcadm.sh is in PATH:
# export PATH=$PATH:$KEYCLOAK_HOME/bin

if [[ "$#" -lt 3 ]]; then
  printf "\n\e[31m\e[1mUsage: [CLIENT_SECRET=xxx] ./bootstrap.sh USERNAME PASSWORD REALM [KEYCLOAK_URL:http://localhost:8080]\n\n"
  printf "Example:\n  CLIENT_SECRET=mysecret ./bootstrap.sh admin password dev\e[0m\n\n"
  printf "Set CLIENT_SECRET to specify client secret."
  exit 1
fi

USER=$1
PASSWORD=$2
REALM=$3
KC_URL=${4:-http://localhost:8080}

echo Authenticating Keycloak master realm at $KC_URL with $USER
kcadm.sh config credentials --server $KC_URL/auth --realm master --user $USER --password $PASSWORD

echo Creating realm $REALM
kcadm.sh create realms -s realm=$REALM -s enabled=true

echo Creating 'webserver' client with service accounts enabled

SECRET=${CLIENT_SECRET:-`openssl rand -hex 20`}
if [ -z "${CLIENT_SECRET}" ]; then
    echo Webserver generated client secret is $SECRET, use CLIENT_SECRET to override
fi

CID=$(kcadm.sh create clients -r $REALM \
  -s clientId=webserver \
  -s serviceAccountsEnabled=true \
  -s 'redirectUris=["*"]' \
  -s secret=$SECRET -i)


echo Getting webserver service account user id
SA_ID=$(kcadm.sh get clients/$CID/service-account-user -r $REALM --fields id --format csv --noquotes)

echo Getting realm-management Client ID
REALM_MANAGEMENT_CID=$(kcadm.sh get clients -r $REALM -q clientId=realm-management  --fields id --format csv --noquotes)

echo Adding webserver service account role
echo [$(kcadm.sh get clients/$REALM_MANAGEMENT_CID/roles/query-users -r $REALM)] > query-users-role.json

kcadm.sh create users/$SA_ID/role-mappings/clients/$REALM_MANAGEMENT_CID -r $REALM -f query-users-role.json
rm -f query-users-role.json

echo Creating 'webclient' public client
CID=$(kcadm.sh create clients -r $REALM -s clientId=webclient \
  -s publicClient=true -s 'redirectUris=["*"]' -s 'webOrigins=["*"]' \
  -s 'fullScopeAllowed=false' -i)

echo Adding audience mapper to add 'webserver' as 'audience' in Access Token
kcadm.sh create clients/$CID/protocol-mappers/models -r $REALM \
  -s name=webserver-audience-mapper -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."included.client.audience"=webserver'
