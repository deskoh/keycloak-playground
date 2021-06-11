# KeyCloak Playground for Access Token

## Accessing Keycloak

* URL: http://keycloak.127.0.0.1.nip.io:8080 / https://keycloak.127.0.0.1.nip.io:8080

* Username: `admin`

* Password: `password`

* OpenID Endpoint Configuration: http://keycloak.127.0.0.1.nip.io:8080/auth/realms/dev/.well-known/openid-configuration

## TLS Server Certs

Replace `./certs/keycloak.key` and `./certs/keycloak.crt` with the private key and certificate and restart the container:

```sh
# Remove containers and volumes
docker-compose down -v
# Start containers
docker-compose up
```

## Access Token

```sh
# Get Access Token for `api` client`
curl -X POST 'http://keycloak.127.0.0.1.nip.io:8080/auth/realms/dev/protocol/openid-connect/token' \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'username=user1' \
  --data-urlencode 'password=password' \
  --data-urlencode 'scope=api' \
  --data-urlencode 'client_id=webclient'
```

Decoded Access Token:

```jsonc
// Single audience
{
  "exp": 1622730164,
  "iat": 1622726564,
  "jti": "db3db14e-94fa-47c3-8630-3d1d6c7e8bcd",
  "iss": "http://keycloak.127.0.0.1.nip.io:8080/auth/realms/dev",
  "aud": "api",
  "sub": "e5346bc2-dd9f-4df8-8d0d-76e49d819811",
  "typ": "Bearer",
  "azp": "webclient",
  "session_state": "8180d144-c84c-4aba-af88-9aa59d50d4fa",
  "acr": "1",
  "resource_access": {
    "api": {
      "roles": ["default"]
    }
  },
  "scope": "api profile",
  "groups": ["GroupA"],
  "preferred_username": "user1"
}

// Multiple audience
{
  "exp": 1623391781,
  "iat": 1623388181,
  "jti": "5770e4ba-e40c-4450-981b-0d5076f9c8e0",
  "iss": "http://keycloak.127.0.0.1.nip.io:8080/auth/realms/dev",
  "aud": [
    "api",
    "webserver"
  ],
  "sub": "e5346bc2-dd9f-4df8-8d0d-76e49d819811",
  "typ": "Bearer",
  "azp": "webclient",
  "session_state": "07e5a45b-4e24-495d-8fcc-8ad470cd610c",
  "acr": "1",
  "resource_access": {
    "api": {
      "roles": [
        "default"
      ]
    },
    "webserver": {
      "roles": [
        "default"
      ]
    }
  },
  "scope": "api profile",
  "preferred_username": "user1"
}
```
