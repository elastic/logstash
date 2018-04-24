package org.logstash.common.kibana;

import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.HashMap;
import java.util.Map;

import org.apache.http.StatusLine;
import org.apache.http.client.fluent.Request;
import org.apache.http.entity.ContentType;

/**
 * Basic Kibana Client. Allows consumers to perform requests against Kibana's HTTP APIs.
 *
 * TODO: SSL options
 * TODO: Auth options
 * TODO: Unit tests
 */
public class Client {
    private URL baseUrl;
    private static final String STATUS_API = "api/status";

    /**
     * @param baseUrl The base URL for Kibana, e.g. http://localhost:5601/
     */
    public Client(URL baseUrl) {
        this.baseUrl = baseUrl;
    }

    /**
     * @param baseUrl The base URL for Kibana, e.g. http://localhost:5601/
     */
    public Client(String baseUrl) throws MalformedURLException {
        this(new URL(baseUrl));
    }

    /**
     * @param protocol  The protocol part of the base URL for Kibana, e.g. http
     * @param host      The hostname part of the base URL for Kibana, e.g. localhost
     * @param port      The port part of the base URL for Kibana, e.g. 5601
     * @param basePath  The base path part of the base URL for Kibana, e.g. /
     * @throws MalformedURLException
     */
    public Client(String protocol, String host, int port, String basePath) throws MalformedURLException {
        this(new URL(protocol, host, port, basePath));
    }

    /**
     * @param protocol  The protocol part of the base URL for Kibana, e.g. http
     * @param host      The hostname part of the base URL for Kibana, e.g. localhost
     * @param port      The port part of the base URL for Kibana, e.g. 5601
     * @throws MalformedURLException
     */
    public Client(String protocol, String host, int port) throws MalformedURLException {
        this(protocol, host, port, "/");
    }

    /**
     * Default constructor. Creates Kibana client with base URL = http://localhost:5601/
     *
     * @throws MalformedURLException
     */
    public Client() throws MalformedURLException {
        this("http", "localhost", 5601);
    }

    /**
     * Checks whether the client can connect to Kibana or not
     *
     * @return true if the client can connect, false otherwise
     */
    public boolean canConnect() {
        try {
            head(STATUS_API);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * Performs an HTTP GET request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/kibana/dashboards/export
     * @return Response body
     * @throws RequestFailedException
     */
    public String get(String relativePath) throws RequestFailedException {
        return get(relativePath, new HashMap<>());
    }

    /**
     * Performs an HTTP GET request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/kibana/dashboards/export
     * @param headers       Headers to include with request
     * @return Response body
     * @throws RequestFailedException
     */
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

    /**
     * Performs an HTTP HEAD request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/status
     * @throws RequestFailedException
     */
    public void head(String relativePath) throws RequestFailedException {
        head(relativePath, new HashMap<>());
    }

    /**
     * Performs an HTTP HEAD request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/status
     * @param headers       Headers to include with request
     * @throws RequestFailedException
     */
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

    /**
     * Performs an HTTP POST request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/kibana/dashboards/import
     * @param requestBody   Body of request
     * @return Response body
     * @throws RequestFailedException
     */
    public String post(String relativePath, String requestBody) throws RequestFailedException {
        return post(relativePath, requestBody, new HashMap<>());
    }

    /**
     * Performs an HTTP POST request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/kibana/dashboards/import
     * @param requestBody   Body of request
     * @param headers       Headers to include with request
     * @return Response body
     * @throws RequestFailedException
     */
    public String post(String relativePath, String requestBody, Map<String, String> headers) throws RequestFailedException {
        String url = makeUrlFrom(relativePath);
        Request request = Request.Post(url);
        headers.forEach(request::addHeader);

        try {
            return request
                    .bodyString(requestBody, ContentType.APPLICATION_JSON)
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

    /**
     * Exception thrown when a request made by this client to the Kibana API fails
     */
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
