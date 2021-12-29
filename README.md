# KeyCloak Playground

## QuickStart

> Silent refresh / SSO-check requires Keycloak HTTPS for Third-Party Cookies support.

```sh
docker-compose build
docker-compose up -d --remove-orphans

# Import DB (after Keycloak is up)
docker-compose exec keycloak /opt/keycloak/bin/kc.sh import --dir /tmp/realm-config

# Install CA at https://keycloak.127.0.0.1.nip.io:8443
# Access http://js-console.127.0.0.1.nip.io:8000/ (login: alice / password)

# Clean up
docker-compose down -v
```

## Accessing Keycloak

* URL: http://keycloak.127.0.0.1.nip.io:8080 / https://keycloak.127.0.0.1.nip.io:8443

* Username: `admin`

* Password: `password`

## Public Client Authentication Code Flow with PKCE and Silent Refresh

To support silent refresh, cross-site cookie is required. However, most browsers require cookies with `SameSite=None` attribute (i.e. cross-site cookies) to also have the `Secure` attribute. Therefore, KeyCloak need to be accessede via HTTPS. The `frame-ancestors=self` property for the realm `Content-Security-Policy` needs to be removed as well.

## Disabling Refresh Token

Refresh token can now be disabled under client settings: `OpenID Connect Compatibility Modes -> Use Refresh Tokens` in Keycloak v13.

## How it works

### Third-Party Cookies Check

A hidden `iframe` [`step1.htm`](https://keycloak.127.0.0.1.nip.io:8443/realms/dev/protocol/openid-connect/3p-cookies/step1.html) is created. This will set 3rd party cookies and redirect to [`step2.htm`](https://keycloak.127.0.0.1.nip.io:8443/realms/dev/protocol/openid-connect/3p-cookies/step2.html). The 3rd party cookie values will be read and the result posted back to parent. See the [limitations](https://www.keycloak.org/docs/latest/securing_apps/#_modern_browsers) for browsers with blocked third-party cookies.

### [Single-Sign Out Detection](https://www.keycloak.org/docs/latest/securing_apps/#session-status-iframe)

A hidden iframe [`login-status-iframe.html`](https://keycloak.127.0.0.1.nip.io:8443/realms/dev/protocol/openid-connect/login-status-iframe.html) will check for Single-Sign Out.

## Refresh Token Behavior

Default configuration for Refresh Token

* 30m expiry.

* New refresh token issued will have expiry extended during refresh request.

* Refresh token can be used multiple times

* After logging out from Keycloak, refresh token will be inactive

   ```json
   {
     "error": "invalid_grant",
     "error_description": "Session not active"
   }
   ```

When `Revoke Refresh Token` is enabled with `Refresh Token Max Reuse` count set to 0.

* Refresh token can only be used at most once (i.e. cannot be reuse).

   ```json
   {
     "error": "invalid_grant",
     "error_description": "Maximum allowed refresh token reuse exceeded"
   }
   ```

* When a user logs in again and a refresh token is issued, refresh token associated with previous login session becomes stale.

   ```json
   {
       "error": "invalid_grant",
       "error_description": "Stale token"
   }
   ```

When `Revoke Refresh Token` is enabled with `Refresh Token Max Reuse` count set to 1.

* Refresh token can only be used at most twice (i.e. reuse once).

* When a refresh token is used

   ```json
   {
       "error": "invalid_grant",
       "error_description": "Stale token"
   }
   ```

## SSL Setup

```sh
# Generate CA key and cert
openssl req -x509 -nodes -jsnewkey rsa:2048 -keyout rootCA.key \
  -days 3650 -out rootCA.crt \
  -subj "/C=SG/OU=www.org/O=MyOrg, Inc./CN=My Org Root CA"

# Generate CSR for keycloak
openssl req -newkey rsa:2048 -nodes -keyout keycloak.key \
  -new -out keycloak.csr \
  -subj "/C=SG/L=Singapore/O=MyOrg, Inc./CN=keycloak" \
  -addext "subjectAltName=DNS:localhost,DNS:keycloak.127.0.0.1.nip.io" \
  -addext "keyUsage=digitalSignature,keyEncipherment"

# Generate CA signed cert for keycloak
openssl x509 -in keycloak.csr \
  -CA rootCA.crt -CAkey rootCA.key -CAcreateserial \
  -req -days 3650 -out keycloak.crt \
  -extfile <(printf "subjectAltName=DNS:localhost,DNS:keycloak,DNS:keycloak.127.0.0.1.nip.io")

# Verify certs
openssl verify -verbose -CAfile rootCA.crt keycloak.crt
```

SSL / TLS debugging

```sh
openssl s_client -connect localhost:8443
```

## Keycloak Configuration

1. Use environment variable: e.g. `KC_HTTPS_CERTIFICATE_FILE=/etc/x509/server.crt`

1. Use command line argument: e.g. `-Dkc.https-certificate-file=/etc/x509/server.crt start auto-build ...`

1. Use build options (for configuration supporting build options): e.g. `start auto-build --https-certificate-file=/etc/x509/server.crt`

## Using STEP CLI

```sh
# Get raw token endpoint response
step oauth --client-id js-console --provider https://localhost:8443/auth/realms/dev/

# Get just the access_token
step oauth --bare --client-id js-console --provider https://localhost:8443/auth/realms/dev/

# Get just the id_token
step oauth --oidc --bare --client-id js-console --provider https://localhost:8443/auth/realms/dev/
```

## References / Resources

[Configuring Keycloak](https://www.keycloak.org/server/configuration)

[Running Keycloak in a container](https://www.keycloak.org/server/containers)

[All configuration](https://www.keycloak.org/server/all-config)

[step oauth](https://smallstep.com/docs/step-cli/reference/oauth)
