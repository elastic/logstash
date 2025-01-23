# Start from the FIPS-compliant base image
FROM docker.elastic.co/wolfi/chainguard-base-fips:latest

# Install OpenJDK 21
RUN apk add --no-cache \
    openjdk-21 \
    bash

# Create directory for security configuration
RUN mkdir -p /etc/java/security
RUN mkdir -p /root/.gradle

# Copy configuration files
COPY java.security /etc/java/security/
COPY java.policy /etc/java/security/
COPY test-init.gradle /tmp/test-init.gradle

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Create working directory
WORKDIR /logstash

# Copy the local Logstash source
COPY . .

# Initial build using JKS truststore
# ENV JAVA_OPTS="-Djavax.net.ssl.trustStore=$JAVA_HOME/lib/security/cacerts -Djavax.net.ssl.trustStoreType=JKS -Djavax.net.ssl.trustStorePassword=changeit"
RUN ./gradlew clean bootstrap assemble installDefaultGems --no-daemon

# Convert to BCFKS trust store
RUN keytool -importkeystore \
    -srckeystore $JAVA_HOME/lib/security/cacerts \
    -destkeystore /etc/java/security/cacerts.bcfks \
    -srcstoretype jks \
    -deststoretype bcfks \
    -providerpath /root/.gradle/caches/modules-2/files-2.1/org.bouncycastle/bc-fips/2.0.0/ee9ac432cf08f9a9ebee35d7cf8a45f94959a7ab/bc-fips-2.0.0.jar \
    -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
    -deststorepass changeit \
    -srcstorepass changeit \
    -noprompt && \
    cp /etc/java/security/cacerts.bcfks /etc/java/security/keystore.bcfks

# ENV JAVA_SECURITY_PROPERTIES=/etc/java/security/java.security
# ENV JAVA_OPTS="\
#     -Djava.security.debug=ssl,provider \
#     -Djava.security.properties=${JAVA_SECURITY_PROPERTIES} \
#     -Djavax.net.ssl.keyStore=/etc/java/security/keystore.bcfks \
#     -Djavax.net.ssl.keyStoreType=BCFKS \
#     -Djavax.net.ssl.keyStoreProvider=BCFIPS \
#     -Djavax.net.ssl.keyStorePassword=changeit \
#     -Djavax.net.ssl.trustStore=/etc/java/security/cacerts.bcfks \
#     -Djavax.net.ssl.trustStoreType=BCFKS \
#     -Djavax.net.ssl.trustStoreProvider=BCFIPS \
#     -Djavax.net.ssl.trustStorePassword=changeit \
#     -Dssl.KeyManagerFactory.algorithm=PKIX \
#     -Dssl.TrustManagerFactory.algorithm=PKIX \
#     -Dorg.bouncycastle.fips.approved_only=true"

# Run tests with BCFKS truststore
CMD ["./gradlew", "--init-script", "/tmp/test-init.gradle", "--info", "--stacktrace", "test"]