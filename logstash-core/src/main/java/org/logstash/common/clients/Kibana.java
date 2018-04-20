package org.logstash.common.clients;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import org.apache.http.StatusLine;
import org.apache.http.client.fluent.Request;
import org.apache.http.entity.ContentType;

// TODO:
// SSL options
// Auth options
// Create custom exception subclass and use it
//
// Javadocs
// @see https://github.com/elastic/logstash/blob/master/logstash-core/lib/logstash/modules/kibana_client.rb
public class Kibana {
    private URL baseUrl;
    private static final String STATUS_API = "api/status";

    public Kibana(URL baseUri) {
        this.baseUrl = baseUri;
    }

    public Kibana(String baseUri) throws MalformedURLException {
        this(new URL(baseUri));
    }

    public Kibana(String protocol, String host, int port, String basePath) throws MalformedURLException {
        this(new URL(protocol, host, port, basePath));
    }

    public Kibana() throws MalformedURLException {
        this("http", "localhost", 5601, "/");
    }

    public boolean canConnect() {
        try {
            head(STATUS_API);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public String get(String relativePath) throws IOException {
        return get(relativePath, new HashMap<>());
    }

    public String get(String relativePath, Map<String, String> headers) throws IOException {
        Request request = Request.Get(makeUrlFrom(relativePath));
        headers.forEach(request::addHeader);

        return request
                .execute()
                .returnContent()
                .asString();
    }

    public void head(String relativePath) throws Exception {
        head(relativePath, new HashMap<>());
    }

    public void head(String relativePath, Map<String, String> headers) throws Exception {
        Request request = Request.Head(makeUrlFrom(relativePath));
        headers.forEach(request::addHeader);

        StatusLine statusLine = request
                .execute()
                .returnResponse()
                .getStatusLine();

        int statusCode = statusLine.getStatusCode();
        if (statusCode >= 400) {
            throw new Exception(statusLine.getReasonPhrase());
        }
    }

    public String post(String relativePath, String jsonContent) throws IOException {
        return post(relativePath, jsonContent, new HashMap<>());
    }

    public String post(String relativePath, String jsonContent, Map<String, String> headers) throws IOException {
        Request request = Request.Post(makeUrlFrom(relativePath));
        headers.forEach(request::addHeader);

        return request
                .bodyString(jsonContent, ContentType.APPLICATION_JSON)
                .execute()
                .returnContent()
                .asString();
    }

    private String makeUrlFrom(String relativePath) {
        String url = this.baseUrl.toString() + '/' + relativePath;
        return url.replaceAll("/\\/+/", "/");
    }

}
