package org.logstash.common.clients;

import com.github.tomakehurst.wiremock.WireMockServer;
import com.github.tomakehurst.wiremock.junit.WireMockRule;
import org.junit.Rule;
import org.junit.Test;

import java.nio.file.Paths;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.options;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

public class HttpClientTest {

    private static final String BIND_ADDRESS = "127.0.0.1";
    private static final String USERNAME = "seger";
    private static final String PASSWORD = "comma_bob";

    @Rule
    public WireMockRule httpServer = new WireMockRule(5601);

    @Test
    public void canMakeHttpRequestWithDefaultSettings() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpRequestWithCustomHostnameAndPort() throws Exception {
        WireMockServer httpServer = new WireMockServer(options()
                .dynamicPort()
                .bindAddress(BIND_ADDRESS));
        httpServer.start();

        try {
            final String path = "/api/hello";
            final String expectedResponseBody = "Hello, World";

            httpServer.stubFor(get(urlPathEqualTo(path))
                    .willReturn(aResponse()
                            .withStatus(200)
                            .withBody(expectedResponseBody))
            );

            HttpClient httpClient = HttpClient.builder()
                    .hostname(BIND_ADDRESS)
                    .port(httpServer.port())
                    .build();

            assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
        } finally {
            httpServer.stop();
        }
    }

    @Test
    public void canMakeHttpRequestWithBasicAuth() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        httpServer.stubFor(get(urlPathEqualTo(path))
                .withBasicAuth(USERNAME, PASSWORD)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.builder()
                .basicAuth(USERNAME, PASSWORD)
                .build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpsRequestWithSslNoVerify() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort());
        httpsServer.start();

        try {
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

            assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void canMakeHttpsRequestWithSslSelfSignedServerCertificate() throws Exception {
        WireMockServer httpsServer = new WireMockServer(options()
                .dynamicHttpsPort()
                .keystorePath(Paths.get(getClass().getResource("selfsigned.jks").toURI()).toString())
                .keystorePassword("elastic"));

        httpsServer.start();

        try {
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

            assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
        } finally {
            httpsServer.stop();
        }
    }

    @Test
    public void cannotMakeHttpsRequestWithoutSslConfiguration() throws Exception {
    }

    @Test
    public void cannotMakeHttpsRequestWithInvalidCaCertificate() throws Exception {
    }

    @Test
    public void canMakeHttpHeadRequest() throws Exception {
    }

    @Test
    public void canMakeHttpPostRequest() throws Exception {
    }

    @Test
    public void canMakeHttpPutRequest() throws Exception {
    }

    @Test
    public void canMakeHttpDeleteRequest() throws Exception {
    }
}
