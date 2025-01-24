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

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Create working directory
WORKDIR /logstash

# Copy the local Logstash source
COPY . .

# Initial build using JKS truststore
# ENV JAVA_OPTS="-Djavax.net.ssl.trustStore=$JAVA_HOME/lib/security/cacerts -Djavax.net.ssl.trustStoreType=JKS -Djavax.net.ssl.trustStorePassword=changeit"
RUN ./gradlew clean bootstrap assemble installDefaultGems testSetup --no-daemon

# CMD ["sleep", "infinity"]
RUN keytool -importkeystore \
    -srckeystore $JAVA_HOME/lib/security/cacerts \
    -destkeystore /etc/java/security/cacerts.bcfks \
    -srcstoretype jks \
    -deststoretype bcfks \
    -providerpath /logstash/logstash-core/lib/jars/bc-fips-2.0.0.jar \
    -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
    -deststorepass changeit \
    -srcstorepass changeit \
    -noprompt

RUN keytool -importkeystore \
    -srckeystore $JAVA_HOME/lib/security/cacerts \
    -destkeystore /etc/java/security/keystore.bcfks \
    -srcstoretype jks \
    -deststoretype bcfks \
    -providerpath /logstash/logstash-core/lib/jars/bc-fips-2.0.0.jar \
    -provider org.bouncycastle.jcajce.provider.BouncyCastleFipsProvider \
    -deststorepass changeit \
    -srcstorepass changeit \
    -noprompt


# Uncomment this out and build for interactive terminal sessions in a container
# Currently this dockerfile is just for running tests, but I have been also using it to
# do manual validation. Need to think more about how to separate concerns. 
ENV JAVA_SECURITY_PROPERTIES=/etc/java/security/java.security
ENV JAVA_OPTS="\
    -Djava.security.debug=ssl,provider \
    -Djava.security.properties=${JAVA_SECURITY_PROPERTIES} \
    -Djavax.net.ssl.keyStore=/etc/java/security/keystore.bcfks \
    -Djavax.net.ssl.keyStoreType=BCFKS \
    -Djavax.net.ssl.keyStoreProvider=BCFIPS \
    -Djavax.net.ssl.keyStorePassword=changeit \
    -Djavax.net.ssl.trustStore=/etc/java/security/cacerts.bcfks \
    -Djavax.net.ssl.trustStoreType=BCFKS \
    -Djavax.net.ssl.trustStoreProvider=BCFIPS \
    -Djavax.net.ssl.trustStorePassword=changeit \
    -Dssl.KeyManagerFactory.algorithm=PKIX \
    -Dssl.TrustManagerFactory.algorithm=PKIX \
    -Dorg.bouncycastle.fips.approved_only=true"

ENV LS_JAVA_OPTS="${JAVA_OPTS}"
# Run tests with BCFKS truststore
CMD ["./gradlew","-PskipJRubySetup=true", "--info", "--stacktrace", "javaTestsOnly", "rubyTestsOnly"]

