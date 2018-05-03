package org.logstash.common.clients;

import java.io.*;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.*;

import org.apache.http.Header;
import org.apache.http.StatusLine;
import org.apache.http.client.methods.*;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClientBuilder;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicHeader;

import javax.net.ssl.*;

/**
 * Easy-to-use HTTP client.
 */
public class HttpClient {
    public enum Protocol { HTTP, HTTPS }

    private CloseableHttpClient httpClient;
    private URL baseUrl;

    private HttpClient(CloseableHttpClient httpClient, URL baseUrl) {
        this.httpClient = httpClient;
        this.baseUrl = baseUrl;
    }

    /**
     * Performs an HTTP GET request
     *
     * @param relativePath  Relative path to resource, e.g. api/kibana/dashboards/export
     * @return Response body
     * @throws RequestFailedException
     */
    public String get(String relativePath) throws RequestFailedException, IOException {
        return get(relativePath, null);
    }

    /**
     * Performs an HTTP GET request
     *
     * @param relativePath  Relative path to resource, e.g. api/kibana/dashboards/export
     * @param headers       Headers to include with request
     * @return Response body
     * @throws RequestFailedException
     * @throws IOException
     */
    public String get(String relativePath, Map<String, String> headers) throws RequestFailedException, IOException {
        String url = makeUrlFrom(relativePath);
        HttpGet request = new HttpGet(url);

        if (headers != null) {
            headers.forEach(request::addHeader);
        }

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
     * Performs an HTTP HEAD request
     *
     * @param relativePath  Relative path to resource, e.g. api/status
     * @throws RequestFailedException
     * @throws IOException
     */
    public void head(String relativePath) throws RequestFailedException, IOException {
        head(relativePath, null);
    }

    /**
     * Performs an HTTP HEAD request
     *
     * @param relativePath  Relative path to resource, e.g. api/status
     * @param headers       Headers to include with request
     * @throws RequestFailedException
     * @throws IOException
     */
    public void head(String relativePath, Map<String, String> headers) throws RequestFailedException, IOException {
        String url = makeUrlFrom(relativePath);
        HttpHead request = new HttpHead(url);

        if (headers != null) {
            headers.forEach(request::addHeader);
        }

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
     * Performs an HTTP POST request
     *
     * @param relativePath  Relative path to resource, e.g. api/kibana/dashboards/import
     * @param requestBody   Body of request
     * @return Response body
     * @throws RequestFailedException
     * @throws IOException
     */
    public String post(String relativePath, String requestBody) throws RequestFailedException, IOException {
        return post(relativePath, requestBody, null);
    }

    /**
     * Performs an HTTP POST request
     *
     * @param relativePath  Relative path to resource, e.g. api/kibana/dashboards/import
     * @param requestBody   Body of request
     * @param headers       Headers to include with request
     * @return Response body
     * @throws RequestFailedException
     * @throws IOException
     */
    public String post(String relativePath, String requestBody, Map<String, String> headers) throws RequestFailedException, IOException {

        String url = makeUrlFrom(relativePath);

        HttpPost request = new HttpPost(url);
        request.setEntity(new StringEntity(requestBody));

        if (headers != null) {
            headers.forEach(request::addHeader);
        }

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
        String url = this.baseUrl.toString().replaceFirst("\\/$", "")
                + '/'
                + relativePath.replaceFirst("^\\/", "");
        return url;
    }

    public static HttpClient build() throws OptionsBuilderException {
        return new OptionsBuilder().build();
    }

    public static OptionsBuilder withOptions() {
        return new OptionsBuilder();
    }

    public static class OptionsBuilder {

        private Protocol protocol;
        private String hostname;
        private int port;
        private String basePath;

        private String basicAuthUsername;
        private String basicAuthPassword;

        private Certificate sslCaCertificate;
        private Certificate sslClientCertificate;
        private byte[] sslClientPrivateKey;
        private boolean sslVerifyServerHostname;
        private boolean sslVerifyServerCredentials;

        private OptionsBuilder() {
            this.protocol = Protocol.HTTP;
            this.hostname = "localhost";
            this.port = 5601;
            this.basePath = "/";
            this.sslVerifyServerHostname = true;
            this.sslVerifyServerCredentials = true;
        }

        public OptionsBuilder protocol(Protocol protocol) {
            this.protocol = protocol;
            if (this.port == 0) {
                this.port = 443;
            }
            return this;
        }

        public OptionsBuilder hostname(String hostname) {
            this.hostname = hostname;
            return this;
        }

        public OptionsBuilder port(int port) {
            this.port = port;
            return this;
        }

        public OptionsBuilder basePath(String basePath) {
            this.basePath = basePath;
            return this;
        }

        public OptionsBuilder basicAuth(String username, String password) {
            this.basicAuthUsername = username;
            this.basicAuthPassword = password;

            return this;
        }

        public OptionsBuilder sslCaCertificate(String caCertificatePath) throws CertificateException, IOException {
            this.sslCaCertificate = getCertificate(caCertificatePath);
            return this;
        }

        public OptionsBuilder sslClientCertificate(String clientCertificatePath) throws CertificateException, IOException {
            this.sslClientCertificate = getCertificate(clientCertificatePath);
            return this;
        }

        public OptionsBuilder sslClientPrivateKey(String clientPrivateKeyPath) throws IOException {
            this.sslClientPrivateKey = getPrivateKey(clientPrivateKeyPath);
            return this;
        }

        public OptionsBuilder sslNoVerifyServerHostname() {
            this.sslVerifyServerHostname = false;
            return this;
        }

        public OptionsBuilder sslNoVerifyServerCredentials() {
            this.sslVerifyServerCredentials = false;
            return this;
        }

        public OptionsBuilder sslNoVerify() {
            return this.sslNoVerifyServerHostname()
                    .sslNoVerifyServerCredentials();
        }

        public HttpClient build() throws OptionsBuilderException {

            URL baseUrl = null;
            try {
                baseUrl = new URL(this.protocol.name().toLowerCase(), this.hostname, this.port, this.basePath);
            } catch (MalformedURLException e) {
                throw new OptionsBuilderException("Unable to create base URL", e);
            }

            if (!usesSsl(baseUrl) && !usesBasicAuth()) {
                CloseableHttpClient httpClient = HttpClients.createDefault();
                return new HttpClient(httpClient, baseUrl);
            }

            HttpClientBuilder httpClientBuilder = HttpClients.custom();

            if (usesSsl(baseUrl)) {
                TrustManager[] trustManagers = null;
                if (this.sslVerifyServerCredentials) {
                    if (this.sslCaCertificate == null) {
                        throw new OptionsBuilderException("Certificate authority not provided. "
                                + "Please provide the certificate authority using the sslCaCertificate method.");
                    }

                    try {
                        KeyStore keystore = getKeyStore();
                        keystore.setCertificateEntry("caCertificate", this.sslCaCertificate);

                        TrustManagerFactory trustManagerFactory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                        trustManagerFactory.init(keystore);

                        trustManagers = trustManagerFactory.getTrustManagers();
                    } catch (Exception e) {
                        throw new OptionsBuilderException("Unable to use provided certificate authority.", e);
                    }
                } else {
                    trustManagers = new TrustManager[] { getAnyTrustManager() };
                }

                KeyManager[] keyManagers = null;
                if ((this.sslClientCertificate != null) && (this.sslClientPrivateKey != null)) {
                    KeyStore keystore = getKeyStore();

                    try {
                        keystore.setCertificateEntry("clientCertificate", this.sslClientCertificate);
                        keystore.setKeyEntry("clientPrivateKey", this.sslClientPrivateKey, new Certificate[]{this.sslClientCertificate});

                        KeyManagerFactory keyManagerFactory = KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
                        keyManagerFactory.init(keystore, null);

                        keyManagers = keyManagerFactory.getKeyManagers();
                    } catch (Exception e) {
                        throw new OptionsBuilderException("Unable to use provided client certificate and/or client private key", e);
                    }
                }

                try {
                    SSLContext sslContext = SSLContext.getInstance("TLS");
                    sslContext.init(keyManagers, trustManagers, null);

                    SSLConnectionSocketFactory sslSocketFactory;
                    if (this.sslVerifyServerHostname) {
                        sslSocketFactory = new SSLConnectionSocketFactory(sslContext, SSLConnectionSocketFactory.STRICT_HOSTNAME_VERIFIER);
                    } else {
                        sslSocketFactory = new SSLConnectionSocketFactory(sslContext, SSLConnectionSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER);
                    }

                    httpClientBuilder.setSSLSocketFactory(sslSocketFactory);
                } catch (Exception e) {
                    throw new OptionsBuilderException("Unable to configure HTTP client with SSL/TLS", e);
                }
            }

            if (usesBasicAuth()) {
                String credentials = this.basicAuthUsername + ":" + this.basicAuthPassword;
                String encodedCredentials = new String(Base64.getEncoder().encode(credentials.getBytes(StandardCharsets.UTF_8)), StandardCharsets.UTF_8);

                List<Header> headerList = Collections.singletonList(new BasicHeader("Authorization", "Basic " + encodedCredentials));
                httpClientBuilder.setDefaultHeaders(headerList);
            }

            return new HttpClient(httpClientBuilder.build(), baseUrl);
        }

        private boolean usesBasicAuth() {
            return (this.basicAuthUsername != null) && (this.basicAuthPassword != null);
        }

        private boolean usesSsl(URL baseUrl) {
            return baseUrl.getProtocol().equals("https");
        }

        private static Certificate getCertificate(String certificateFilePath) throws CertificateException, IOException {
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

        private static byte[] getPrivateKey(String privateKeyPath) throws IOException {
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

        private static KeyStore getKeyStore() throws OptionsBuilderException {
            KeyStore keystore;
            try {
                keystore = KeyStore.getInstance(KeyStore.getDefaultType());
                keystore.load(null, null);
            } catch (Exception e) {
                throw new OptionsBuilderException("Unable to create keystore", e);
            }
            return keystore;
        }

        private static X509TrustManager getAnyTrustManager() {
            return new X509TrustManager() {
                @Override
                public void checkClientTrusted(X509Certificate[] x509Certificates, String s) {

                }

                @Override
                public void checkServerTrusted(X509Certificate[] x509Certificates, String s) {

                }

                @Override
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }
            };
        }

    }

    public static class OptionsBuilderException extends Exception {
        public OptionsBuilderException(String errorMessage, Throwable cause) {
            super(errorMessage, cause);
        }

        public OptionsBuilderException(String errorMessage) {
            super(errorMessage);
        }
    }

    /**
     * Exception thrown when a request made by this client to the HTTP resource fails
     */
    public static class RequestFailedException extends Exception {
        RequestFailedException(String method, String url, Throwable cause) {
            super(makeMessage(method, url, null), cause);
        }

        RequestFailedException(String method, String url, String reason) {
            super(makeMessage(method, url, reason));
        }

        private static String makeMessage(String method, String url, String reason) {
            String message = "Could not make " + method + " " + url + " request";
            if (reason != null) {
                message += "; reason: " + reason;
            }
            return message;
        }
    }
}
