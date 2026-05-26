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

/**
 * Configuration for {@link OtelMetricsService}.
 *
 * <p>Use {@link #builder(String, String, String, String)} to construct an instance.
 * Required parameters are the node identity and transport settings; all other parameters
 * are optional and have sensible defaults.
 *
 * <p>Example:
 * <pre>{@code
 * OtelMetricsConfig config = OtelMetricsConfig
 *     .builder(nodeId, nodeName, endpoint, protocol)
 *     .intervalMs(10_000L)
 *     .headers("Authorization=ApiKey my-key")
 *     .build();
 * }</pre>
 */
public class OtelMetricsConfig {

    private final String endpoint;
    private final String nodeId;
    private final String nodeName;
    private final long intervalMs;
    private final String protocol;
    private final String resourceAttributes;
    private final String headers;
    private final String serviceName;
    private final String certificatePath;
    private final String clientKeyPath;
    private final String clientCertificatePath;

    private OtelMetricsConfig(Builder builder) {
        this.endpoint = builder.endpoint;
        this.nodeId = builder.nodeId;
        this.nodeName = builder.nodeName;
        this.intervalMs = builder.intervalMs;
        this.protocol = builder.protocol;
        this.resourceAttributes = builder.resourceAttributes;
        this.headers = builder.headers;
        this.serviceName = builder.serviceName;
        this.certificatePath = builder.certificatePath;
        this.clientKeyPath = builder.clientKeyPath;
        this.clientCertificatePath = builder.clientCertificatePath;
    }

    public static Builder builder(String nodeId, String nodeName, String endpoint, String protocol) {
        return new Builder(nodeId, nodeName, endpoint, protocol);
    }

    public String getEndpoint() { return endpoint; }
    public String getNodeId() { return nodeId; }
    public String getNodeName() { return nodeName; }
    public long getIntervalMs() { return intervalMs; }
    public String getProtocol() { return protocol; }
    public String getResourceAttributes() { return resourceAttributes; }
    public String getHeaders() { return headers; }
    public String getServiceName() { return serviceName; }
    public String getCertificatePath() { return certificatePath; }
    public String getClientKeyPath() { return clientKeyPath; }
    public String getClientCertificatePath() { return clientCertificatePath; }

    public static class Builder {

        private final String nodeId;
        private final String nodeName;
        private final String endpoint;
        private final String protocol;
        private long intervalMs = 10_000L;
        private String resourceAttributes;
        private String headers;
        private String serviceName;
        private String certificatePath;
        private String clientKeyPath;
        private String clientCertificatePath;

        private Builder(String nodeId, String nodeName, String endpoint, String protocol) {
            this.nodeId = nodeId;
            this.nodeName = nodeName;
            this.endpoint = endpoint;
            this.protocol = protocol;
        }

        public Builder intervalMs(long intervalMs) {
            this.intervalMs = intervalMs;
            return this;
        }

        public Builder resourceAttributes(String resourceAttributes) {
            this.resourceAttributes = resourceAttributes;
            return this;
        }

        public Builder headers(String headers) {
            this.headers = headers;
            return this;
        }

        public Builder serviceName(String serviceName) {
            this.serviceName = serviceName;
            return this;
        }

        public Builder certificatePath(String certificatePath) {
            this.certificatePath = certificatePath;
            return this;
        }

        public Builder clientKeyPath(String clientKeyPath) {
            this.clientKeyPath = clientKeyPath;
            return this;
        }

        public Builder clientCertificatePath(String clientCertificatePath) {
            this.clientCertificatePath = clientCertificatePath;
            return this;
        }

        public OtelMetricsConfig build() {
            return new OtelMetricsConfig(this);
        }
    }
}
