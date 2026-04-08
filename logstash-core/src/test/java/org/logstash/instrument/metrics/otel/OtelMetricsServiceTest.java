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
