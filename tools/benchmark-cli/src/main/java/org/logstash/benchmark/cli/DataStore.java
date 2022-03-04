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


package org.logstash.benchmark.cli;

import java.io.Closeable;
import java.io.IOException;
import java.util.Collections;
import java.util.Map;
import org.apache.http.HttpHost;
import org.apache.http.HttpStatus;
import org.apache.http.entity.ContentType;
import org.apache.http.nio.entity.NStringEntity;
import org.elasticsearch.client.RestClient;
import org.logstash.benchmark.cli.ui.LsMetricStats;
import org.logstash.benchmark.cli.util.LsBenchJsonUtil;
import org.openjdk.jmh.util.ListStatistics;

public interface DataStore extends Closeable {

    /**
     * Dummy {@link DataStore} that does nothing.
     */
    DataStore NONE = new DataStore() {
        @Override
        public void store(final Map<LsMetricStats, ListStatistics> data) {
        }

        @Override
        public void close() {
        }
    };

    /**
     * @param data Measured Data
     * @throws IOException On Failure
     */
    void store(Map<LsMetricStats, ListStatistics> data) throws IOException;

    /**
     * Datastore backed by Elasticsearch.
     */
    final class ElasticSearch implements DataStore {

        /**
         * Low Level Elasticsearch {@link RestClient}.
         */
        private final RestClient client;

        /**
         * Metadata for the current benchmark run.
         */
        private final Map<String, Object> meta;

        /**
         * Ctor.
         * @param host Elasticsearch Hostname
         * @param port Elasticsearch Port
         * @param schema {@code "http"} or {@code "https"} 
         * @param meta Metadata
         */
        ElasticSearch(final String host, final int port, final String schema,
            final Map<String, Object> meta) {
            client = RestClient.builder(new HttpHost(host, port, schema)).build();
            this.meta = Collections.unmodifiableMap(meta);
        }

        @Override
        public void store(final Map<LsMetricStats, ListStatistics> data) throws IOException {
            if (client.performRequest(
                "POST", "/logstash-benchmarks/measurement/",
                Collections.emptyMap(),
                new NStringEntity(
                    LsBenchJsonUtil.serializeEsResult(data, meta), ContentType.APPLICATION_JSON
                )
            ).getStatusLine().getStatusCode() != HttpStatus.SC_CREATED) {
                throw new IllegalStateException(
                    "Failed to save measurement to Elasticsearch.");
            }
        }

        @Override
        public void close() throws IOException {
            client.close();
        }
    }
}
