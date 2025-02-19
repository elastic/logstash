# Start from the FIPS-compliant base image
FROM docker.elastic.co/wolfi/chainguard-base-fips:latest

# Create logstash user and group first to ensure consistent UID/GID
# Inspired by https://github.com/elastic/ci-agent-images/blob/03f2adb3e749500017dd1c9dc08061556df43f6f/container-images/platform-ingest/logstash-ci-no-root/Dockerfile.py#L44C1-L47
RUN addgroup -g 1002 logstash && \
    adduser -S -h /home/logstash -s /bin/bash -u 1002 -G logstash logstash

# Install OpenJDK 21
RUN apk add --no-cache \
    openjdk-21 \
    bash \
    git \
    curl \
    make \
    # CODEREVIEW: I think make, gcc and glibc-dev are all in build-base package if we want that
    gcc \
    glibc-dev

# Create directories with correct ownership
RUN mkdir -p /etc/java/security && \
    mkdir -p /home/logstash/.gradle && \
    chown -R logstash:logstash /home/logstash/.gradle && \
    chown -R logstash:logstash /etc/java/security

# Copy JVM configuration files: TODO manage these consistently
COPY --chown=logstash:logstash x-pack/distributions/internal/observabilitySRE/config/security/java.security /etc/java/security/
COPY --chown=logstash:logstash x-pack/distributions/internal/observabilitySRE/config/security/java.policy /etc/java/security/

# Create and set ownership of working directory
WORKDIR /logstash
RUN chown -R logstash:logstash /logstash

# Switch to logstash user for remaining operations
USER logstash

# Copy the local Logstash source with correct ownership
COPY --chown=logstash:logstash . .

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Initial build using JKS truststore
RUN ./gradlew clean bootstrap assemble installDefaultGems

# Convert JKS to BCFKS for truststore and keystore
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

ENV JAVA_SECURITY_PROPERTIES=/etc/java/security/java.security
ENV LS_JAVA_OPTS="\
    -Dio.netty.ssl.provider=JDK \
    # Enable debug logging for ensuring BCFIPS is being used if needed
    # -Djava.security.debug=ssl,provider,certpath \
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

# Example test run, most use cases will override this
CMD ["./gradlew", "--info", "--stacktrace", "-PrunTestsInFIPSMode=true", "runIntegrationTests"]