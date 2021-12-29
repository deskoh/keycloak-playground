FROM quay.io/keycloak/keycloak:17.0.0 as builder

ENV KC_METRICS_ENABLED=true
# ENV KC_FEATURES=token-exchange
ENV KC_DB=mariadb
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:17.0.0
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
# RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore

ENV KEYCLOAK_ADMIN=admin \
    KEYCLOAK_ADMIN_PASSWORD=change_me \
    KC_DB_URL_HOST=mariadb \
    KC_DB_USERNAME=keycloak \
    KC_DB_PASSWORD=change_me

# Uncomment behind proxy / in production
# ENV KC_PROXY=edge \
#     KC_HOSTNAME=localhost:8443


ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start"]