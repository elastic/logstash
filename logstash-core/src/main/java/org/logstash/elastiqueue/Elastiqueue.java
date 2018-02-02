package org.logstash.elastiqueue;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpHost;
import org.apache.http.entity.StringEntity;
import org.apache.http.message.BasicHeader;
import org.elasticsearch.client.Response;
import org.elasticsearch.client.RestClient;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.util.*;
import java.util.concurrent.BlockingQueue;

public class Elastiqueue implements Closeable {
    private final RestClient client;
    private static final Header defaultHeaders[] = {
            new BasicHeader("Content-Type", "application/json"),
    };

    public Elastiqueue(HttpHost... hosts) throws IOException {
        client = RestClient.builder(hosts).build();
        setup();
    }
     public Topic topic(String name, int numPartitions) {
        return new Topic(this, name, numPartitions);
     }

    private void setup() throws IOException {
        putTemplate();
    }

    private void putTemplate() throws IOException {
        simpleRequest(
                "put",
                "/_template/esqueue_segments",
                new StringEntity(template())
        );

    }

    public Response simpleRequest(String method, String endpoint, HttpEntity body) throws IOException {
        return client.performRequest(method, endpoint, Collections.emptyMap(), body, defaultHeaders);
    }

    private String template() throws IOException {
        URL resource = getClass().getClassLoader().getResource("esqueue_segments_template.json");

        try (InputStream is = resource.openStream()) {
            return new Scanner(is, "UTF-8").useDelimiter("\\A").next();
        }
    }

    public RestClient getClient() {
        return client;
    }

    @Override
    public void close() throws IOException {
        client.close();
    }
}
