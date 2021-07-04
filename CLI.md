# Keycloak CLI

## Running CLI

```sh
# Run in container (session will be stored in $HOME/.keycloak/kcadm.config inside container)
docker exec -it keycloak bash
cd $JBOSS_HOME/bin

# To run locally, copy bin directory to keycloak directory in current working directory
docker cp keycloak:/opt/jboss/keycloak/bin keycloak
cd keycloak
```

## Authenticating

```sh
KC_URL=http://localhost:8080
# Keycloak session stored in `~/.keycloak/kcadm.config`
./kcadm.sh config credentials --server $KC_URL/auth --realm master --user admin --password password
```

## Example Operations

```sh
# Realm to create
REALM=dev
./kcadm.sh create realms -s realm=$REALM -s enabled=true
```

### Bearer-Only Client

```sh
./kcadm.sh create clients -r $REALM -s clientId=webserver -s bearerOnly=true
```

### Confidential Client

```sh
# Create confidential client `webserver` with service accounts enabled (to allow client credentials grant)
# Add `-s secret xxxxxx` to use existing secret
CID=$(./kcadm.sh create clients -r $REALM -s clientId=webserver -s serviceAccountsEnabled=true -s 'redirectUris=["*"]' -i)

# Get confidential client secret
./kcadm.sh get clients/$CID/client-secret -r $REALM

# Get service account user id
SA_ID=$(./kcadm.sh get clients/$CID/service-account-user -r $REALM --fields id --format csv --noquotes)

# Get realm-management client ID
REALM_MANAGEMENT_CID=$(./kcadm.sh get clients -r $REALM -q clientId=realm-management  --fields id --format csv --noquotes)

# Add service account role
## Get query-users role (surround object with [])
echo [$(./kcadm.sh get clients/$REALM_MANAGEMENT_CID/roles/query-users -r $REALM)] > query-users-role.json
## Add role
./kcadm.sh create users/$SA_ID/role-mappings/clients/$REALM_MANAGEMENT_CID -r $REALM -f query-users-role.json
```

### Public Client

```sh
# Create public client `webclient` (with Full Scopes disabled)
CID=$(./kcadm.sh create clients -r $REALM -s clientId=webclient \
  -s publicClient=true -s 'redirectUris=["*"]' -s 'webOrigins=["*"]' \
  -s 'fullScopeAllowed=false' -i)

# Add audience mapper to add `webserver` as `audience` in Access Token
./kcadm.sh create clients/$CID/protocol-mappers/models -r $REALM \
  -s name=webserver-audience-mapper -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper \
  -s 'config."access.token.claim"=true' -s 'config."id.token.claim"=false' \
  -s 'config."included.client.audience"=webserver'
```
