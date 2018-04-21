package org.logstash.common.kibana;

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
//
// Javadocs
// Unit tests
public class Client {
    private URL baseUrl;
    private static final String STATUS_API = "api/status";

    public Client(URL baseUri) {
        this.baseUrl = baseUri;
    }

    public Client(String baseUri) throws MalformedURLException {
        this(new URL(baseUri));
    }

    public Client(String protocol, String host, int port, String basePath) throws MalformedURLException {
        this(new URL(protocol, host, port, basePath));
    }

    public Client(String protocol, String host, int port) throws MalformedURLException {
        this(protocol, host, port, "/");
    }

    public Client() throws MalformedURLException {
        this("http", "localhost", 5601);
    }

    public boolean canConnect() {
        try {
            head(STATUS_API);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public String get(String relativePath) throws RequestFailedException {
        return get(relativePath, new HashMap<>());
    }

    public String get(String relativePath, Map<String, String> headers) throws RequestFailedException {
        String url = makeUrlFrom(relativePath);
        Request request = Request.Get(url);
        headers.forEach(request::addHeader);

        try {
            return request
                    .execute()
                    .returnContent()
                    .asString();
        } catch (IOException e) {
            throw new RequestFailedException("GET", url, e);
        }
    }

    public void head(String relativePath) throws RequestFailedException {
        head(relativePath, new HashMap<>());
    }

    public void head(String relativePath, Map<String, String> headers) throws RequestFailedException {
        String url = makeUrlFrom(relativePath);
        Request request = Request.Head(url);
        headers.forEach(request::addHeader);

        StatusLine statusLine;
        try {
            statusLine = request
                    .execute()
                    .returnResponse()
                    .getStatusLine();
        } catch (IOException e) {
            throw new RequestFailedException("HEAD", url ,e);
        }

        int statusCode = statusLine.getStatusCode();
        if (statusCode >= 400) {
            throw new RequestFailedException("HEAD", url ,statusLine.getReasonPhrase());
        }
    }

    public String post(String relativePath, String jsonContent) throws RequestFailedException {
        return post(relativePath, jsonContent, new HashMap<>());
    }

    public String post(String relativePath, String jsonContent, Map<String, String> headers) throws RequestFailedException {
        String url = makeUrlFrom(relativePath);
        Request request = Request.Post(url);
        headers.forEach(request::addHeader);

        try {
            return request
                    .bodyString(jsonContent, ContentType.APPLICATION_JSON)
                    .execute()
                    .returnContent()
                    .asString();
        } catch (IOException e) {
            throw new RequestFailedException("POST", url, e);
        }
    }

    private String makeUrlFrom(String relativePath) {
        String url = this.baseUrl.toString() + '/' + relativePath;
        return url.replaceAll("/\\/+/", "/");
    }

    public static class RequestFailedException extends Exception {
        RequestFailedException(String method, String url, Throwable cause) {
            super(makeMessage(method, url, null), cause);
        }

        RequestFailedException(String method, String url, String reason) {
            super(makeMessage(method, url, reason));
        }

        private static String makeMessage(String method, String url, String reason) {
            String message = "Could not make " + method + " " + url + " request to Kibana";
            if (reason != null) {
                message += "; reason: " + reason;
            }
            return message;
        }
    }

}
