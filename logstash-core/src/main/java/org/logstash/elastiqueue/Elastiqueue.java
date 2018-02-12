package org.logstash.elastiqueue;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.HttpHost;
import org.apache.http.entity.StringEntity;
import org.apache.http.message.BasicHeader;
import org.elasticsearch.client.Response;
import org.elasticsearch.client.RestClient;
import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.Closeable;
import java.io.IOException;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.util.*;
import java.util.concurrent.BlockingQueue;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class Elastiqueue implements Closeable {
    private final RestClient client;
    private static final Header defaultHeaders[] = {
            new BasicHeader("Content-Type", "application/json"),
    };

    public static Elastiqueue make(RubyArray hosts) throws IOException {
        HttpHost[] javaHosts = new HttpHost[hosts.size()];
        for (int i = 0; i < hosts.size(); i++) {
            javaHosts[i] = HttpHost.create(hosts.get(i).toString());
        }
        return new Elastiqueue(javaHosts);
    }

    public static Elastiqueue make(String... hostStrings) throws IOException {
        HttpHost[] hosts = new HttpHost[hostStrings.length];
        for (int i = 0; i < hostStrings.length; i++) {
            hosts[i] = HttpHost.create(hostStrings[i]);
        }
        return new Elastiqueue(hosts);
    }

    public Elastiqueue(HttpHost... hosts) throws IOException {
        client = RestClient.builder(hosts).build();
        setup();
    }
     public Topic topic(String name, int numPartitions) {
        return new Topic(this, name, numPartitions);
     }

    private void setup() throws IOException {
        putTemplate("elastiqueue_segments");
        putTemplate("elastiqueue_meta");
    }

    private void putTemplate(String id) throws IOException {
        simpleRequest(
                "put",
                "/_template/" + id,
                new StringEntity(template(id))
        );

    }

    Response simpleRequest(String method, String endpoint, HttpEntity body) throws IOException {
        return client.performRequest(method, endpoint, Collections.emptyMap(), body, defaultHeaders);
    }

    Response simpleRequest(String method, String endpoint, String body) throws IOException {
        StringEntity bodyEntity = new StringEntity(body);
        return simpleRequest(method, endpoint, bodyEntity);
    }

    Response simpleRequest(String method, String endpoint) throws IOException {
        return client.performRequest(method, endpoint, Collections.emptyMap(), new StringEntity(""), defaultHeaders);
    }

    Response simpleRequest(String method, String endpoint, byte[] body) throws IOException {
        return simpleRequest(method, endpoint, new String(body, "UTF-8"));
    }

    private String template(String id) throws IOException {
        String templateFilename = id + "_template.json";
        URL resource = getClass().getClassLoader().getResource(templateFilename);

        if (resource == null) {
            throw new IOException("Could not find template resource " + templateFilename);
        }

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
