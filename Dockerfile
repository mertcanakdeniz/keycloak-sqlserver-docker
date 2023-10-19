FROM quay.io/keycloak/keycloak:latest as builder
#FROM jboss/keycloak:latest as builder
# Enable health and metrics support
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Configure a database vendor
ENV KC_DB=mssql


WORKDIR /opt/keycloak
# for demonstration purposes only, please make sure to use proper certificates in production instead
#RUN keytool -genkeypair -storepass password -storetype PKCS12 -keyalg RSA -keysize 2048 -dname "CN=server" -alias server -ext "SAN:c=DNS:localhost,IP:127.0.0.1" -keystore conf/server.keystore
#RUN /opt/keycloak/bin/kc.sh --verbose  build 
#RUN /opt/keycloak/bin/kc.sh -Dkc.db.tx-type=enable -Dkc.db-driver=com.microsoft.sqlserver.jdbc.SQLServerDriver --db=mssql

COPY ./provider/keycloakify.jar /opt/keycloak/providers/

# main provider
COPY ./providers/keycloak-phone-provider-2.3.4-snapshot.jar /opt/keycloak/providers/

#resources
COPY ./providers/keycloak-phone-provider.resources-2.3.4-snapshot.jar /opt/keycloak/providers/

#dummy provider
COPY ./providers/keycloak-sms-provider-dummy-2.3.4-snapshot.jar /opt/keycloak/providers/

#tencent provider
#COPY keycloak-sms-provider-tencent-2.3.4-snapshot.jar /opt/keycloak/providers/


# xa module  and quarkus configurations
RUN /opt/keycloak/bin/kc.sh build --db=mssql  --transaction-xa-enabled=true -Dquarkus.debug.enabled=true -Dquarkus.debug.port=5005  --debug

COPY quarkus.properties /opt/keycloak/conf/
COPY keycloak.conf /opt/keycloak/conf/


FROM quay.io/keycloak/keycloak:latest

COPY --from=builder /opt/keycloak/ /opt/keycloak/
# change these values to point to a running postgres instance
ENV KC_DB=mssql
ENV KC_DB_URL=jdbc:sqlserver://<url>:1433;databaseName=Keycloak;encrypt=false;trustServerCertificate=false;loginTimeout=30
ENV KC_DB_USERNAME=<username>
ENV KC_DB_PASSWORD=
#ENV KC_HOSTNAME=
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
#CMD ["start-dev"]
