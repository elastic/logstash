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
