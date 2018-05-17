package org.logstash.common.clients;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.junit.WireMockRule;
import org.junit.Rule;
import org.junit.Test;
import org.logstash.common.clients.HttpClient.RequestFailedException;

import java.net.InetAddress;
import java.nio.file.Paths;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.options;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

public class HttpClientTest {

    @Rule
    public WireMockRule httpServer = new WireMockRule(options().dynamicPort());

    @Test
    public void canMakeHttpRequestWithAlmostDefaultSettings() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port()) // We set this one setting so we don't need to run this test as a superuser
                .build();

        try(HttpClient.CloseableResponse closeableResponse = httpClient.get(path)) {
            assertThat(closeableResponse.getBodyAsString()).isEqualTo(expectedResponseBody);
        }
    }

    @Test
    public void canMakeHttpRequestWithCustomHostnameAndPort() throws Exception {
        final String BIND_ADDRESS = InetAddress.getLoopbackAddress().getHostAddress();

        WireMockServer localhostHttpServer = new WireMockServer(options()
                .dynamicPort()
                .bindAddress(BIND_ADDRESS));

        try {
            localhostHttpServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            localhostHttpServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .hostname(BIND_ADDRESS)
                    .port(localhostHttpServer.port())
                    .build();

            try(HttpClient.CloseableResponse closeableResponse = httpClient.get(path)) {
                assertThat(closeableResponse.getBodyAsString()).isEqualTo(expectedResponseBody);
            }
        } finally {
            localhostHttpServer.stop();
        }
    }

    @Test
    public void canMakeHttpRequestWithBasicAuth() throws Exception {
        final String USERNAME = "seger";
        final String PASSWORD = "comma_bob";

        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(get(urlPathEqualTo(path))
                .withBasicAuth(USERNAME, PASSWORD)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .basicAuth(USERNAME, PASSWORD)
                .build();

        try(HttpClient.CloseableResponse closeableResponse = httpClient.get(path)) {
            assertThat(closeableResponse.getBodyAsString()).isEqualTo(expectedResponseBody);
        }
    }

    @Test
    public void canMakeHttpsRequestWithSslNoVerify() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort());

        try {
            httpsServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpsServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .protocol(HttpClient.Protocol.HTTPS)
                    .port(httpsServer.httpsPort())
                    .sslNoVerify()
                    .build();

            try(HttpClient.CloseableResponse closeableResponse = httpClient.get(path)) {
                assertThat(closeableResponse.getBodyAsString()).isEqualTo(expectedResponseBody);
            }
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void canMakeHttpsRequestWithSslSelfSignedServerCertificate() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort()
                .keystorePath(Paths.get(getClass().getResource("server.jks").toURI()).toString())
                .keystorePassword("elastic"));

        try {
            httpsServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpsServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .protocol(HttpClient.Protocol.HTTPS)
                    .port(httpsServer.httpsPort())
                    .sslCaCertificate(Paths.get(getClass().getResource("server.crt").toURI()).toString())
                    .build();

            try(HttpClient.CloseableResponse response = httpClient.get(path)) {
                assertThat(response.getBodyAsString()).isEqualTo(expectedResponseBody);
            }
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void canMakeHttpsRequestWithSslSelfSignedServerAndClientCertificates() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort()
                .keystorePath(Paths.get(getClass().getResource("server.jks").toURI()).toString())
                .keystorePassword("elastic")
                .needClientAuth(true)
                .trustStorePath(Paths.get(getClass().getResource("server.jks").toURI()).toString())
                .trustStorePassword("elastic")
        );

        try {
            httpsServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpsServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .protocol(HttpClient.Protocol.HTTPS)
                    .port(httpsServer.httpsPort())
                    .sslCaCertificate(Paths.get(getClass().getResource("server.crt").toURI()).toString())
                    .sslClientCertificate(Paths.get(getClass().getResource("client.crt").toURI()).toString())
                    .sslClientPrivateKey(Paths.get(getClass().getResource("client.key").toURI()).toString())
                    .build();

            try(HttpClient.CloseableResponse response = httpClient.get(path)) {
                assertThat(response.getBodyAsString()).isEqualTo(expectedResponseBody);
            }
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void cantMakeHttpsRequestWithUnverifiedHostnameAndSslNoVerifyServerHostname() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort()
                .keystorePath(Paths.get(getClass().getResource("server_no_san.jks").toURI()).toString())
                .keystorePassword("elastic")
        );

        try {
            httpsServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpsServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .protocol(HttpClient.Protocol.HTTPS)
                    .port(httpsServer.httpsPort())
                    .sslCaCertificate(Paths.get(getClass().getResource("server_no_san.crt").toURI()).toString())
                    .sslNoVerifyServerHostname()
                    .build();

            try(HttpClient.CloseableResponse response = httpClient.get(path)) {
                assertThat(response.getBodyAsString()).isEqualTo(expectedResponseBody);
            }
        } finally {
            httpsServer.stop();
        }
    }

    @Test(expected = RequestFailedException.class)
    public void throwsExceptionForHttpsRequestWithUnverifiedHostname() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort()
                .keystorePath(Paths.get(getClass().getResource("server_no_san.jks").toURI()).toString())
                .keystorePassword("elastic")
        );

        try {
            httpsServer.start();
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpsServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .protocol(HttpClient.Protocol.HTTPS)
                    .port(httpsServer.httpsPort())
                    .sslCaCertificate(Paths.get(getClass().getResource("server_no_san.crt").toURI()).toString())
                    .build();

            try(HttpClient.CloseableResponse response = httpClient.get(path)) {}
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void canMakeHttpPostRequest() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(post(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        String body = "Hello!";
        try(HttpClient.CloseableResponse response = httpClient.post(path, body)) {
            assertThat(response.getBodyAsString()).isEqualTo(expectedResponseBody);
        }
    }

    @Test
    public void canMakeHttpPutRequest() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(put(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        String body = "Hello!";
        try(HttpClient.CloseableResponse response = httpClient.put(path, body)) {
            assertThat(response.getBodyAsString()).isEqualTo(expectedResponseBody);
        }
    }

    @Test
    public void returnsBadRequestForUnsuccessfulHeadRequest() throws Exception {
        final String path = "/api/hello";

        httpServer.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(400))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        HttpClient.Response response = httpClient.head(path);
        assertThat(response.getStatusCode()).isEqualTo(400);
    }

    @Test
    public void returnsBadRequestForUnsuccessfulGetRequest() throws Exception {
        final String path = "/api/hello";

        httpServer.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(400))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        try(HttpClient.CloseableResponse response = httpClient.get(path)) {
            assertThat(response.getStatusCode()).isEqualTo(400);
        }
    }

    @Test
    public void returnsBadRequestForUnsuccessfulPostRequest() throws Exception {
        final String path = "/api/hello";

        httpServer.stubFor(post(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(400))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        String body = "Hello!";
        try(HttpClient.CloseableResponse response = httpClient.post(path, body)) {
            assertThat(response.getStatusCode()).isEqualTo(400);
        }
    }

    @Test
    public void returnsBadRequestForUnsuccessfulPutRequest() throws Exception {
        final String path = "/api/hello";

        httpServer.stubFor(put(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(400))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        String body = "Hello!";
        try(HttpClient.CloseableResponse response = httpClient.put(path, body)) {
            assertThat(response.getStatusCode()).isEqualTo(400);
        }
    }

    @Test
    public void returnsBadRequestForUnsuccessfulDeleteRequest() throws Exception {
        final String path = "/api/hello";

        httpServer.stubFor(delete(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(400))
        );

        HttpClient httpClient = HttpClient.builder()
                .port(httpServer.port())
                .build();

        HttpClient.Response response = httpClient.delete(path);
        assertThat(response.getStatusCode()).isEqualTo(400);
    }
}
