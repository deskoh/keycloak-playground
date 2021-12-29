@echo off
setlocal enableDelayedExpansion

REM Example script for Keycloak configuration
REM Assumes kcadm.bat is in PATH:
REM PATH=%PATH%;%KEYCLOAK_HOME%/bin

if [%3]==[] goto usage

set USER=%1
set PASSWORD=%2
set REALM=%3
set KC_URL=%4

if not defined KC_URL (
  set KC_URL=http://localhost:8080
)

set SECRET=%CLIENT_SECRET%
if not defined SECRET (
  call openssl rand -hex 20 > SECRET.txt
  set /p SECRET=<SECRET.txt
  del SECRET.txt
)
if not defined CLIENT_SECRET echo Webserver client secret is %SECRET%, use CLIENT_SECRET to override

echo Authenticating Keycloak master realm at %KC_URL% with %USER%
call kcadm config credentials --server %KC_URL% --realm master --user %USER% --password %PASSWORD%

echo Creating realm %REALM%
call kcadm create realms -s realm=%REALM% -s enabled=true

echo Creating 'webserver' client with service accounts enabled

call kcadm create clients -r %REALM% ^
  -s clientId=webserver ^
  -s serviceAccountsEnabled=true ^
  -s "redirectUris=[\"*\"]" ^
  -s secret=%SECRET% -i > CID.txt
set /p CID=<CID.txt
del CID.txt

echo Getting webserver service account user id
call kcadm get clients/%CID%/service-account-user -r %REALM% --fields id --format csv --noquotes > SA_ID.txt
set /p SA_ID=<SA_ID.txt
del SA_ID.txt

echo Getting realm-management Client ID
call kcadm get clients -r %REALM% -q clientId=realm-management --fields id --format csv --noquotes > REALM_MANAGEMENT_CID.txt
set /p REALM_MANAGEMENT_CID=<REALM_MANAGEMENT_CID.txt
del REALM_MANAGEMENT_CID.txt

echo Adding webserver service account role
echo [ > query-users-role.json
call kcadm get clients/%REALM_MANAGEMENT_CID%/roles/query-users -r %REALM% >> query-users-role.json
echo ] >> query-users-role.json

call kcadm create users/%SA_ID%/role-mappings/clients/%REALM_MANAGEMENT_CID% -r %REALM% -f query-users-role.json
del query-users-role.json

echo Creating 'webclient' public client
call kcadm create clients -r %REALM% -s clientId=webclient ^
  -s publicClient=true -s "redirectUris=[\"*\"]" -s "webOrigins=[\"*\"]" ^
  -s fullScopeAllowed=false -i > CID.txt
set /p CID=<CID.txt
del CID.txt

echo Adding audience mapper to add 'webserver' as 'audience' in Access Token
call kcadm create clients/%CID%/protocol-mappers/models -r %REALM% ^
  -s name=webserver-audience-mapper -s protocol=openid-connect -s protocolMapper=oidc-audience-mapper ^
  -s "config.\"access.token.claim\"=true" -s "config.\"id.token.claim\"=false" ^
  -s "config.\"included.client.audience\"=webserver"

goto :eof

:usage
  echo Usage: %0 USERNAME PASSWORD REALM [KEYCLOAK_URL:http://localhost:8080]
  echo Example:
  echo     bootstrap admin password dev
  echo Set CLIENT_SECRET to specify client secret.
  exit /B 1
