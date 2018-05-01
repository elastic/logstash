package org.logstash.common.kibana;

import java.io.*;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.util.*;

import org.apache.http.Header;
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
import org.apache.http.message.BasicHeader;

import javax.net.ssl.*;

/**
 * Basic Kibana Client. Allows consumers to perform requests against Kibana's HTTP APIs.
 *
 * TODO: SSL options
 * TODO: Auth options
 * TODO: Unit tests
 */
public class Client {
    public enum Protocol { HTTP, HTTPS };

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
        String url = this.baseUrl.toString().replaceFirst("\\/$", "")
                + '/'
                + relativePath.replaceFirst("^\\/", "");
        return url;
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

    // TODO: Throw custom exception wrapping lower-level exceptions
    public static Client getInstance() throws CertificateException, UnrecoverableKeyException, NoSuchAlgorithmException, IOException, KeyManagementException, KeyStoreException {
        return new Builder().getInstance();
    }

    public static Builder withOptions() {
        return new Builder();
    }

    public static class Builder {

        private Protocol protocol;
        private String hostname;
        private int port;
        private String basePath;

        private String basicAuthUsername;
        private String basicAuthPassword;

        private boolean useStrictSslVerificationMode;
        private Certificate caCertificate;
        private Certificate clientPublicKeyCertificate;
        private byte[] clientPrivateKey;

        public Builder protocol(Protocol protocol) {
            this.protocol = protocol;
            return this;
        }

        public Builder hostname(String hostname) {
            this.hostname = hostname;
            return this;
        }

        public Builder port(int port) {
            this.port = port;
            return this;
        }

        public Builder basePath(String basePath) {
            this.basePath = basePath;
            return this;
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        public Builder ssl(boolean useStrictSslVerificationMode, String caCertificatePath, String clientPublicKeyCertificatePath, String clientPrivateKeyPath) throws CertificateException, IOException {
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
        public Builder ssl(boolean useStrictSslVerificationMode, String caCertificatePath) throws CertificateException, IOException {
            return ssl(useStrictSslVerificationMode, caCertificatePath, null, null);
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        public Builder ssl(boolean useStrictSslVerificationMode) throws CertificateException, IOException {
            return ssl(useStrictSslVerificationMode, null, null, null);
        }

        public Builder basicAuth(String username, String password) {
            this.basicAuthUsername = username;
            this.basicAuthPassword = password;

            return this;
        }

        // TODO: Throw custom exception wrapping lower-level exceptions
        // TODO: Decide how much work to do in this build() method vs. in ssl() method
        public Client getInstance() throws CertificateException, NoSuchAlgorithmException, IOException, KeyStoreException, KeyManagementException, UnrecoverableKeyException {

            Protocol protocol = this.protocol;
            if (protocol == null) {
                protocol = Protocol.HTTP;
            }

            String hostname = this.hostname;
            if (hostname == null) {
                hostname = "localhost";
            }

            int port = this.port;
            if (port == 0) {
                port = 5601;
            }

            String basePath = this.basePath;
            if (basePath == null) {
                basePath = "/";
            }

            URL baseUrl = new URL(protocol.name().toLowerCase(), hostname, port, basePath);

            if (!usesSsl(baseUrl) && !usesBasicAuth()) {
                CloseableHttpClient httpClient = HttpClients.createDefault();
                return new Client(httpClient, baseUrl);
            }

            HttpClientBuilder httpClientBuilder = HttpClients.custom();

            if (usesSsl(baseUrl)) {
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
                String credentials = this.basicAuthUsername + ":" + this.basicAuthPassword;
                String encodedCredentials = new String(Base64.getEncoder().encode(credentials.getBytes(StandardCharsets.UTF_8)), StandardCharsets.UTF_8);

                List<Header> headerList = Collections.singletonList(new BasicHeader("Authorization", "Basic " + encodedCredentials));
                httpClientBuilder.setDefaultHeaders(headerList);
            }

            return new Client(httpClientBuilder.build(), baseUrl);
        }

        private boolean usesSsl(URL baseUrl) {
            return (baseUrl.getProtocol() == "https") && this.useStrictSslVerificationMode;
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
