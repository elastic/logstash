package org.logstash.common.kibana;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.util.HashMap;
import java.util.Map;

import org.apache.http.StatusLine;
import org.apache.http.auth.AuthScope;
import org.apache.http.auth.UsernamePasswordCredentials;
import org.apache.http.client.CredentialsProvider;
import org.apache.http.client.methods.*;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.BasicCredentialsProvider;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.impl.client.HttpClients;

import javax.net.ssl.*;

/**
 * Basic Kibana Client. Allows consumers to perform requests against Kibana's HTTP APIs.
 *
 * TODO: SSL options
 * TODO: Auth options
 * TODO: Unit tests
 */
public class Client {
    private CloseableHttpClient httpClient;
    private URL baseUrl;

    private static final String STATUS_API = "api/status";

    private Client(CloseableHttpClient httpClient, URL baseUrl) {
        this.httpClient = httpClient;
        this.baseUrl = baseUrl;
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
    public String get(String relativePath) throws RequestFailedException, IOException {
        return get(relativePath, new HashMap<>());
    }

    /**
     * Performs an HTTP GET request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/kibana/dashboards/export
     * @param headers       Headers to include with request
     * @return Response body
     * @throws RequestFailedException
     * @throws IOException
     */
    public String get(String relativePath, Map<String, String> headers) throws RequestFailedException, IOException {
        String url = makeUrlFrom(relativePath);

        // TODO: use this.httpClient instead
        HttpGet request = new HttpGet(url);
        headers.forEach(request::addHeader);
        CloseableHttpResponse response = null;

        try {
            response = httpClient.execute(request);
            return response
                    .getEntity()
                    .getContent()
                    .toString();
        } catch (IOException e) {
            throw new RequestFailedException("GET", url, e);
        } finally {
            if (response != null) {
                response.close();
            }
        }
    }

    /**
     * Performs an HTTP HEAD request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/status
     * @throws RequestFailedException
     * @throws IOException
     */
    public void head(String relativePath) throws RequestFailedException, IOException {
        head(relativePath, new HashMap<>());
    }

    /**
     * Performs an HTTP HEAD request against Kibana's API
     *
     * @param relativePath  Relative path to Kibana API resource, e.g. api/status
     * @param headers       Headers to include with request
     * @throws RequestFailedException
     * @throws IOException
     */
    public void head(String relativePath, Map<String, String> headers) throws RequestFailedException, IOException {
        String url = makeUrlFrom(relativePath);

        // TODO: use this.httpClient instead
        HttpHead request = new HttpHead(url);
        headers.forEach(request::addHeader);

        CloseableHttpResponse response = null;
        StatusLine statusLine;

        try {
            response = httpClient.execute(request);
            statusLine =  response.getStatusLine();
        } catch (IOException e) {
            throw new RequestFailedException("HEAD", url ,e);
        } finally {
            if (response != null) {
                response.close();
            }
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
     * @throws IOException
     */
    public String post(String relativePath, String requestBody) throws RequestFailedException, IOException {
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
     * @throws IOException
     */
    public String post(String relativePath, String requestBody, Map<String, String> headers) throws RequestFailedException, IOException {

        String url = makeUrlFrom(relativePath);

        // TODO: use this.httpClient instead
        HttpPost request = new HttpPost(url);
        headers.forEach(request::addHeader);
        request.setEntity(new StringEntity(requestBody));

        CloseableHttpResponse response = null;

        try {
            response = httpClient.execute(request);
            return response
                    .getEntity()
                    .getContent()
                    .toString();
        } catch (IOException e) {
            throw new RequestFailedException("POST", url, e);
        } finally {
            if (response != null) {
                response.close();
            }
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

    public static class Builder {

        private URL baseUrl;
        private boolean useStrictSslVerificationMode;
        private Certificate caCertificate;
        private Certificate clientPublicKeyCertificate;
        private byte[] clientPrivateKey;
        private String basicAuthUsername;
        private String basicAuthPassword;

        /**
         * @param baseUrl The base URL for Kibana, e.g. http://localhost:5601/
         */
        public Builder(URL baseUrl) {
            this.baseUrl = baseUrl;
            this.useStrictSslVerificationMode = true;
        }

        /**
         * @param baseUrl The base URL for Kibana, e.g. http://localhost:5601/
         */
        public Builder(String baseUrl) throws MalformedURLException {
            this(new URL(baseUrl));
        }

        /**
         * @param protocol  The protocol part of the base URL for Kibana, e.g. http
         * @param host      The hostname part of the base URL for Kibana, e.g. localhost
         * @param port      The port part of the base URL for Kibana, e.g. 5601
         * @param basePath  The base path part of the base URL for Kibana, e.g. /
         * @throws MalformedURLException
         */
        public Builder(String protocol, String host, int port, String basePath) throws MalformedURLException {
            this(new URL(protocol, host, port, basePath));
        }

        /**
         * @param protocol  The protocol part of the base URL for Kibana, e.g. http
         * @param host      The hostname part of the base URL for Kibana, e.g. localhost
         * @param port      The port part of the base URL for Kibana, e.g. 5601
         * @throws MalformedURLException
         */
        public Builder(String protocol, String host, int port) throws MalformedURLException {
            this(protocol, host, port, "/");
        }

        /**
         * Default constructor. Creates Kibana client with base URL = http://localhost:5601/
         *
         * @throws MalformedURLException
         */
        public Builder() throws MalformedURLException {
            this("http", "localhost", 5601);
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        public Builder withSSL(boolean useStrictSslVerificationMode, String caCertificatePath, String clientPublicKeyCertificatePath, String clientPrivateKeyPath) throws CertificateException, IOException {
            this.useStrictSslVerificationMode = useStrictSslVerificationMode;

            if (caCertificatePath != null) {
                this.caCertificate = getCertificate(caCertificatePath);
            }

            if (clientPublicKeyCertificatePath != null) {
                this.clientPublicKeyCertificate = getCertificate(clientPublicKeyCertificatePath);
            }

            if (clientPrivateKeyPath != null) {
                this.clientPrivateKey = getPrivateKey(clientPrivateKeyPath);
            }

            return this;
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        public Builder withSSL(boolean useStrictSslVerificationMode, String caCertificatePath) throws CertificateException, IOException {
            return withSSL(useStrictSslVerificationMode, caCertificatePath, null, null);
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        public Builder withSSL(boolean useStrictSslVerificationMode) throws CertificateException, IOException {
            return withSSL(useStrictSslVerificationMode, null, null, null);
        }

        public Builder withBasicAuth(String username, String password) {
            this.basicAuthUsername = username;
            this.basicAuthPassword = password;

            return this;
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        // TODO: Decide how much work to do in this build() method vs. in withSSL() method
        public Client build() throws CertificateException, NoSuchAlgorithmException, IOException, KeyStoreException, KeyManagementException, UnrecoverableKeyException {

            if (!usesSsl() && !usesBasicAuth()) {
                CloseableHttpClient httpClient = HttpClients.createDefault();
                return new Client(httpClient, this.baseUrl);
            }

            HttpClientBuilder httpClientBuilder = HttpClients.custom();

            if (usesSsl()) {
                TrustManager[] trustManagers = null;
                if (this.caCertificate != null) {
                    KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
                    keystore.load(null, null);

                    keystore.setCertificateEntry("caCertificate", this.caCertificate);

                    TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                    trustManagerFactory.init(keystore);

                    trustManagers = trustManagerFactory.getTrustManagers();
                }

                KeyManager[] keyManagers = null;
                if ((this.clientPublicKeyCertificate != null) && (this.clientPrivateKey != null)) {
                    KeyStore keystore = KeyStore.getInstance(KeyStore.getDefaultType());
                    keystore.load(null, null);

                    keystore.setCertificateEntry("clientPublicKeyCertificate", this.clientPublicKeyCertificate);
                    keystore.setKeyEntry("clientPrivateKey", this.clientPrivateKey, new Certificate[]{this.clientPublicKeyCertificate});

                    KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                    keyManagerFactory.init(keystore, null);

                    keyManagers = keyManagerFactory.getKeyManagers();
                }

                SSLContext sslContext = SSLContext.getDefault();
                sslContext.init(keyManagers, trustManagers, null);

                SSLConnectionSocketFactory sslSocketFactory;
                if (useStrictSslVerificationMode) {
                    sslSocketFactory = new SSLConnectionSocketFactory(sslContext, SSLConnectionSocketFactory.STRICT_HOSTNAME_VERIFIER);
                } else {
                    sslSocketFactory = new SSLConnectionSocketFactory(sslContext, SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
                }

                httpClientBuilder.setSSLSocketFactory(sslSocketFactory);
            }

            if (usesBasicAuth()) {
                CredentialsProvider basicAuthCredentialsProvider = new BasicCredentialsProvider();
                UsernamePasswordCredentials credentials = new UsernamePasswordCredentials(this.basicAuthUsername, this.basicAuthPassword);
                basicAuthCredentialsProvider.setCredentials(AuthScope.ANY, credentials);

                httpClientBuilder.setDefaultCredentialsProvider(basicAuthCredentialsProvider);
            }

            return new Client(httpClientBuilder.build(), this.baseUrl);
        }

        private boolean usesSsl() {
            return (this.baseUrl.getProtocol() == "https") && this.useStrictSslVerificationMode;
        }

        private boolean usesBasicAuth() {
            return (this.basicAuthUsername != null) && (this.basicAuthPassword != null);
        }

        private Certificate getCertificate(String certificateFilePath) throws CertificateException, IOException {
            FileInputStream fis = new FileInputStream(certificateFilePath);

            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            Certificate certificate;

            try {
                certificate = cf.generateCertificate(fis);
            } finally {
                fis.close();
            }

            return certificate;
        }

        private byte[] getPrivateKey(String privateKeyPath) throws IOException {
            FileInputStream fis = new FileInputStream(privateKeyPath);
            ByteArrayOutputStream buffer = new ByteArrayOutputStream();

            int numBytesRead;
            byte[] data = new byte[16384];

            while ((numBytesRead = fis.read(data)) != -1) {
                buffer.write(data, 0, numBytesRead);
            }
            buffer.flush();

            return buffer.toByteArray();
        }
    }

}
