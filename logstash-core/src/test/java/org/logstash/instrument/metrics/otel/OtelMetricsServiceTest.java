/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.instrument.metrics.otel;

import io.opentelemetry.api.common.AttributeKey;
import io.opentelemetry.api.common.Attributes;
import io.opentelemetry.api.common.AttributesBuilder;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.Logger;
import org.apache.logging.log4j.core.appender.AbstractAppender;
import org.apache.logging.log4j.core.config.Property;
import org.junit.After;
import org.junit.Before;
import org.junit.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Unit tests for {@link OtelMetricsService}
 */
public class OtelMetricsServiceTest {

    private TestAppender testAppender;
    private Logger logger;

    @Before
    public void setUp() {
        logger = (Logger) LogManager.getLogger(OtelMetricsService.class);
        testAppender = new TestAppender("TestAppender");
        testAppender.start();
        logger.addAppender(testAppender);
        logger.setLevel(Level.WARN);
    }

    @After
    public void tearDown() {
        logger.removeAppender(testAppender);
        testAppender.stop();
    }

    @Test
    public void parseResourceAttributesWithValidPairs() {
        AttributesBuilder builder = Attributes.builder();

        OtelMetricsService.parseResourceAttributes("foo=bar,baz=qux", builder);

        Attributes attrs = builder.build();
        assertThat(attrs.get(AttributeKey.stringKey("foo"))).isEqualTo("bar");
        assertThat(attrs.get(AttributeKey.stringKey("baz"))).isEqualTo("qux");
        assertThat(testAppender.getLogMessages()).isEmpty();
    }

    @Test
    public void parseResourceAttributesWithMalformedPairs() {
        AttributesBuilder builder = Attributes.builder();

        OtelMetricsService.parseResourceAttributes("foo,bar=baz,this,another=thing", builder);

        Attributes attrs = builder.build();
        // Valid pairs should be parsed
        assertThat(attrs.get(AttributeKey.stringKey("bar"))).isEqualTo("baz");
        assertThat(attrs.get(AttributeKey.stringKey("another"))).isEqualTo("thing");
        // Malformed pairs should not be present
        assertThat(attrs.get(AttributeKey.stringKey("foo"))).isNull();
        assertThat(attrs.get(AttributeKey.stringKey("this"))).isNull();

        // Should have logged warnings for malformed pairs
        List<String> warnings = testAppender.getLogMessages();
        assertThat(warnings).hasSize(2);
        assertThat(warnings.get(0)).contains("foo");
        assertThat(warnings.get(0)).contains("expected format 'key=value'");
        assertThat(warnings.get(1)).contains("this");
    }

    @Test
    public void parseResourceAttributesWithEmptyPairs() {
        AttributesBuilder builder = Attributes.builder();

        OtelMetricsService.parseResourceAttributes("foo=bar,,baz=qux,", builder);

        Attributes attrs = builder.build();
        assertThat(attrs.get(AttributeKey.stringKey("foo"))).isEqualTo("bar");
        assertThat(attrs.get(AttributeKey.stringKey("baz"))).isEqualTo("qux");
        // Empty pairs should be silently skipped, no warnings
        assertThat(testAppender.getLogMessages()).isEmpty();
    }

    @Test
    public void parseResourceAttributesWithWhitespace() {
        AttributesBuilder builder = Attributes.builder();

        OtelMetricsService.parseResourceAttributes(" foo = bar , baz = qux ", builder);

        Attributes attrs = builder.build();
        assertThat(attrs.get(AttributeKey.stringKey("foo"))).isEqualTo("bar");
        assertThat(attrs.get(AttributeKey.stringKey("baz"))).isEqualTo("qux");
    }

    @Test
    public void parseResourceAttributesWithValueContainingEquals() {
        AttributesBuilder builder = Attributes.builder();

        OtelMetricsService.parseResourceAttributes("url=http://example.com?foo=bar", builder);

        Attributes attrs = builder.build();
        assertThat(attrs.get(AttributeKey.stringKey("url"))).isEqualTo("http://example.com?foo=bar");
    }

    @Test
    public void normalizeHttpEndpointAppendsPathWhenMissing() {
        // Standard OTel Collector endpoint with explicit port
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://localhost:4318"))
                .isEqualTo("http://localhost:4318/v1/metrics");

        // Prometheus OTLP endpoint with explicit port
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://prometheus:9090/api/v1/otlp"))
                .isEqualTo("http://prometheus:9090/api/v1/otlp/v1/metrics");

        // Grafana Cloud endpoint - adds default port 443 for https
        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://otlp-gateway.grafana.net/otlp"))
                .isEqualTo("https://otlp-gateway.grafana.net:443/otlp/v1/metrics");
    }

    @Test
    public void normalizeHttpEndpointPreservesFullPath() {
        // Endpoint already has /v1/metrics - should not double-append
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://localhost:4318/v1/metrics"))
                .isEqualTo("http://localhost:4318/v1/metrics");

        // Elastic Cloud or other managed service with full path - adds default port 443
        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://my-cluster.apm.us-east-1.aws.elastic.cloud/v1/metrics"))
                .isEqualTo("https://my-cluster.apm.us-east-1.aws.elastic.cloud:443/v1/metrics");
    }

    @Test
    public void normalizeHttpEndpointAddsDefaultPortForHttp() {
        // HTTP without port should get port 80
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://collector.example.com"))
                .isEqualTo("http://collector.example.com:80/v1/metrics");
    }

    @Test
    public void normalizeHttpEndpointAddsDefaultPortForHttps() {
        // HTTPS without port should get port 443
        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://collector.example.com"))
                .isEqualTo("https://collector.example.com:443/v1/metrics");
    }

    @Test
    public void normalizeHttpEndpointPreservesExplicitPort() {
        // Explicit port should be preserved
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://localhost:8080"))
                .isEqualTo("http://localhost:8080/v1/metrics");

        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://collector.example.com:9443"))
                .isEqualTo("https://collector.example.com:9443/v1/metrics");
    }

    // ==================== getSystemProperty tests ====================

    @Test
    public void getSystemPropertyReturnsDefaultWhenNotSet() {
        String value = OtelMetricsService.getSystemProperty("test.nonexistent.property.12345", "default-value");
        assertThat(value).isEqualTo("default-value");
    }

    @Test
    public void getSystemPropertyReturnsNullWhenNoDefaultAndNotSet() {
        String value = OtelMetricsService.getSystemProperty("test.nonexistent.property.12345", null);
        assertThat(value).isNull();
    }

    @Test
    public void getSystemPropertyReadsSystemProperty() {
        String propName = "test.otel.config.property.read";
        try {
            System.setProperty(propName, "system-prop-value");
            String value = OtelMetricsService.getSystemProperty(propName, "default");
            assertThat(value).isEqualTo("system-prop-value");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getSystemPropertyIgnoresEmptySystemProperty() {
        String propName = "test.otel.config.property.empty";
        try {
            System.setProperty(propName, "");
            String value = OtelMetricsService.getSystemProperty(propName, "default");
            assertThat(value).isEqualTo("default");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getSystemPropertyTakesPrecedenceOverDefault() {
        String propName = "test.otel.config.property.precedence";
        try {
            System.setProperty(propName, "from-system-property");
            String value = OtelMetricsService.getSystemProperty(propName, "from-default");
            assertThat(value).isEqualTo("from-system-property");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getSystemPropertyPreservesWhitespaceInValue() {
        String propName = "test.otel.config.property.whitespace";
        try {
            System.setProperty(propName, "  value with spaces  ");
            String value = OtelMetricsService.getSystemProperty(propName, "default");
            assertThat(value).isEqualTo("  value with spaces  ");
        } finally {
            System.clearProperty(propName);
        }
    }

    // ==================== normalizeProtocol tests ====================

    @Test
    public void normalizeProtocolConvertsHttpProtobufToHttp() {
        assertThat(OtelMetricsService.normalizeProtocol("http/protobuf")).isEqualTo("http");
    }

    @Test
    public void normalizeProtocolConvertsHttpProtobufCaseInsensitive() {
        assertThat(OtelMetricsService.normalizeProtocol("HTTP/PROTOBUF")).isEqualTo("http");
        assertThat(OtelMetricsService.normalizeProtocol("Http/Protobuf")).isEqualTo("http");
    }

    @Test
    public void normalizeProtocolPreservesOtherValues() {
        assertThat(OtelMetricsService.normalizeProtocol("http")).isEqualTo("http");
        assertThat(OtelMetricsService.normalizeProtocol("grpc")).isEqualTo("grpc");
        assertThat(OtelMetricsService.normalizeProtocol("GRPC")).isEqualTo("GRPC");
    }

    // ========================================
    // resolveServiceName tests
    // ========================================

    @Test
    public void resolveServiceNameReturnsDefaultWhenNothingProvided() {
        String serviceName = OtelMetricsService.resolveServiceName(null);
        assertThat(serviceName).isEqualTo("logstash");
    }

    @Test
    public void resolveServiceNameReturnsDefaultForEmptyLogstashYml() {
        String serviceName = OtelMetricsService.resolveServiceName("");
        assertThat(serviceName).isEqualTo("logstash");
    }

    @Test
    public void resolveServiceNameReturnsLogstashYmlWhenProvided() {
        String serviceName = OtelMetricsService.resolveServiceName("my-logstash");
        assertThat(serviceName).isEqualTo("my-logstash");
    }

    @Test
    public void resolveServiceNameSystemPropertyTakesPrecedence() {
        try {
            System.setProperty("otel.service.name", "from-system-property");
            String serviceName = OtelMetricsService.resolveServiceName("from-logstash-yml");
            assertThat(serviceName).isEqualTo("from-system-property");
        } finally {
            System.clearProperty("otel.service.name");
        }
    }

    @Test
    public void resolveServiceNameSystemPropertyIgnoresEmptyValue() {
        try {
            System.setProperty("otel.service.name", "");
            String serviceName = OtelMetricsService.resolveServiceName("from-logstash-yml");
            assertThat(serviceName).isEqualTo("from-logstash-yml");
        } finally {
            System.clearProperty("otel.service.name");
        }
    }

    // ========================================
    // readPemFile tests
    // ========================================

    @Test
    public void readPemFileReturnsNullForNullPath() {
        assertThat(OtelMetricsService.readPemFile(null)).isNull();
    }

    @Test
    public void readPemFileReturnsNullForEmptyPath() {
        assertThat(OtelMetricsService.readPemFile("")).isNull();
    }

    @Test
    public void readPemFileReadsBytesFromFile() throws IOException {
        String pemContent = "-----BEGIN CERTIFICATE-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ==\n-----END CERTIFICATE-----\n";
        Path tempFile = Files.createTempFile("test-cert", ".pem");
        try {
            Files.writeString(tempFile, pemContent);
            byte[] result = OtelMetricsService.readPemFile(tempFile.toString());
            assertThat(result).isEqualTo(pemContent.getBytes());
        } finally {
            Files.deleteIfExists(tempFile);
        }
    }

    @Test
    public void readPemFileThrowsForNonExistentPath() {
        assertThatThrownBy(() -> OtelMetricsService.readPemFile("/nonexistent/path/ca.pem"))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("/nonexistent/path/ca.pem");
    }

    // ========================================
    // parseHeaders tests
    // ========================================

    @Test
    public void parseHeadersParsesAuthorizationHeader() {
        Map<String, String> headers = OtelMetricsService.parseHeaders("Authorization=ApiKey my-key");
        assertThat(headers).containsEntry("Authorization", "ApiKey my-key");
        assertThat(headers).hasSize(1);
    }

    @Test
    public void parseHeadersParsesMultipleHeaders() {
        Map<String, String> headers = OtelMetricsService.parseHeaders("Authorization=Bearer token,X-Custom=foo");
        assertThat(headers).containsEntry("Authorization", "Bearer token");
        assertThat(headers).containsEntry("X-Custom", "foo");
        assertThat(headers).hasSize(2);
    }

    @Test
    public void parseHeadersHandlesValueContainingEquals() {
        // Base64-encoded API keys contain '=' padding
        Map<String, String> headers = OtelMetricsService.parseHeaders("Authorization=ApiKey abc123==");
        assertThat(headers).containsEntry("Authorization", "ApiKey abc123==");
    }

    @Test
    public void parseHeadersTrimsWhitespace() {
        Map<String, String> headers = OtelMetricsService.parseHeaders(" Authorization = Bearer token , X-Custom = foo ");
        assertThat(headers).containsEntry("Authorization", "Bearer token");
        assertThat(headers).containsEntry("X-Custom", "foo");
    }

    @Test
    public void parseHeadersSkipsEmptyEntries() {
        Map<String, String> headers = OtelMetricsService.parseHeaders("Authorization=Bearer token,,X-Custom=foo,");
        assertThat(headers).hasSize(2);
        assertThat(testAppender.getLogMessages()).isEmpty();
    }

    @Test
    public void parseHeadersWarnsOnMalformedEntry() {
        logger.setLevel(Level.WARN);
        Map<String, String> headers = OtelMetricsService.parseHeaders("Authorization=Bearer token,malformed");
        assertThat(headers).containsEntry("Authorization", "Bearer token");
        assertThat(headers).hasSize(1);
        assertThat(testAppender.getLogMessages()).hasSize(1);
        assertThat(testAppender.getLogMessages().get(0)).contains("malformed");
    }

    /**
     * Test appender to capture log messages
     */
    private static class TestAppender extends AbstractAppender {
        private final List<String> logMessages = new ArrayList<>();

        protected TestAppender(String name) {
            super(name, null, null, true, Property.EMPTY_ARRAY);
        }

        @Override
        public void append(LogEvent event) {
            logMessages.add(event.getMessage().getFormattedMessage());
        }

        public List<String> getLogMessages() {
            return new ArrayList<>(logMessages);
        }
    }
}
