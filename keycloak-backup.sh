# Backup keycloak config to `keycloak-backup` directory
# Note: User `admin` will be created it it exists, ignored otherwise. Can specify any existing user with aribtrary password as well
mkdir keycloak-backup
chmod 777 keycloak-backup

docker run --rm \
    --name keycloak_exporter \
    --network local \
    -v $(pwd)/keycloak-backup:/tmp/realm-config:Z\
    -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=password \
    -e DB_VENDOR=mariadb -e DB_ADDR=mariadb -e DB_USER=keycloak -e DB_PASSWORD=password \
    jboss/keycloak:13.0.1 \
    -Dkeycloak.migration.action=export \
    -Dkeycloak.migration.provider=dir \
    -Dkeycloak.migration.dir=/tmp/realm-config \
    -Dkeycloak.migration.usersExportStrategy=SAME_FILE
