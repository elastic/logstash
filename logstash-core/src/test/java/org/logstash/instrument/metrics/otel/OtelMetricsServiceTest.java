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

import java.util.ArrayList;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

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
        // Standard OTel Collector endpoint
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://localhost:4318"))
                .isEqualTo("http://localhost:4318/v1/metrics");

        // Prometheus OTLP endpoint
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://prometheus:9090/api/v1/otlp"))
                .isEqualTo("http://prometheus:9090/api/v1/otlp/v1/metrics");

        // Grafana Cloud endpoint
        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://otlp-gateway.grafana.net/otlp"))
                .isEqualTo("https://otlp-gateway.grafana.net/otlp/v1/metrics");
    }

    @Test
    public void normalizeHttpEndpointPreservesFullPath() {
        // Endpoint already has /v1/metrics - should not double-append
        assertThat(OtelMetricsService.normalizeHttpEndpoint("http://localhost:4318/v1/metrics"))
                .isEqualTo("http://localhost:4318/v1/metrics");

        // Elastic Cloud or other managed service with full path
        assertThat(OtelMetricsService.normalizeHttpEndpoint("https://my-cluster.apm.us-east-1.aws.elastic.cloud/v1/metrics"))
                .isEqualTo("https://my-cluster.apm.us-east-1.aws.elastic.cloud/v1/metrics");
    }

    // ==================== propertyToEnvVar tests ====================

    @Test
    public void propertyToEnvVarConvertsDotsToUnderscores() {
        assertThat(OtelMetricsService.propertyToEnvVar("otel.exporter.otlp.endpoint"))
                .isEqualTo("OTEL_EXPORTER_OTLP_ENDPOINT");
    }

    @Test
    public void propertyToEnvVarConvertsToUpperCase() {
        assertThat(OtelMetricsService.propertyToEnvVar("otel.exporter.otlp.metrics.endpoint"))
                .isEqualTo("OTEL_EXPORTER_OTLP_METRICS_ENDPOINT");
    }

    @Test
    public void propertyToEnvVarConvertsHyphensToUnderscores() {
        assertThat(OtelMetricsService.propertyToEnvVar("otel.some-property.name"))
                .isEqualTo("OTEL_SOME_PROPERTY_NAME");
    }

    @Test
    public void propertyToEnvVarHandlesAllOtelProperties() {
        assertThat(OtelMetricsService.propertyToEnvVar("otel.metric.export.interval"))
                .isEqualTo("OTEL_METRIC_EXPORT_INTERVAL");

        assertThat(OtelMetricsService.propertyToEnvVar("otel.exporter.otlp.protocol"))
                .isEqualTo("OTEL_EXPORTER_OTLP_PROTOCOL");

        assertThat(OtelMetricsService.propertyToEnvVar("otel.exporter.otlp.headers"))
                .isEqualTo("OTEL_EXPORTER_OTLP_HEADERS");

        assertThat(OtelMetricsService.propertyToEnvVar("otel.resource.attributes"))
                .isEqualTo("OTEL_RESOURCE_ATTRIBUTES");
    }

    // ==================== getConfigValue tests ====================

    @Test
    public void getConfigValueReturnsDefaultWhenNotSet() {
        String value = OtelMetricsService.getConfigValue("test.nonexistent.property.12345", "default-value");
        assertThat(value).isEqualTo("default-value");
    }

    @Test
    public void getConfigValueReturnsNullWhenNoDefaultAndNotSet() {
        String value = OtelMetricsService.getConfigValue("test.nonexistent.property.12345", null);
        assertThat(value).isNull();
    }

    @Test
    public void getConfigValueReadsSystemProperty() {
        String propName = "test.otel.config.property.read";
        try {
            System.setProperty(propName, "system-prop-value");
            String value = OtelMetricsService.getConfigValue(propName, "default");
            assertThat(value).isEqualTo("system-prop-value");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getConfigValueIgnoresEmptySystemProperty() {
        String propName = "test.otel.config.property.empty";
        try {
            System.setProperty(propName, "");
            String value = OtelMetricsService.getConfigValue(propName, "default");
            assertThat(value).isEqualTo("default");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getConfigValueSystemPropertyTakesPrecedenceOverDefault() {
        String propName = "test.otel.config.property.precedence";
        try {
            System.setProperty(propName, "from-system-property");
            String value = OtelMetricsService.getConfigValue(propName, "from-default");
            assertThat(value).isEqualTo("from-system-property");
        } finally {
            System.clearProperty(propName);
        }
    }

    @Test
    public void getConfigValuePreservesWhitespaceInValue() {
        String propName = "test.otel.config.property.whitespace";
        try {
            System.setProperty(propName, "  value with spaces  ");
            String value = OtelMetricsService.getConfigValue(propName, "default");
            assertThat(value).isEqualTo("  value with spaces  ");
        } finally {
            System.clearProperty(propName);
        }
    }

    // Note: Environment variable tests are not included because System.getenv()
    // cannot be easily mocked in unit tests without additional libraries.
    // The environment variable lookup is tested implicitly through integration tests.

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
