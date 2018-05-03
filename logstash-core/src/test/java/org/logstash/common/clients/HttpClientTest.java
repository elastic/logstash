package org.logstash.common.clients;

import com.github.tomakehurst.wiremock.junit.WireMockRule;
import org.junit.Rule;
import org.junit.Test;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.options;
import static org.assertj.core.api.AssertionsForClassTypes.assertThat;

public class HttpClientTest {

    private static final String BIND_ADDRESS = "127.0.0.1";
    private static final int HTTPS_PORT = 5443;
    private static final String USERNAME = "seger";
    private static final String PASSWORD = "comma_bob";

    @Rule
    public WireMockRule defaultHttp = new WireMockRule(5601);

    @Rule
    public WireMockRule customHttp = new WireMockRule(options().dynamicPort().bindAddress(BIND_ADDRESS));

    @Rule
    public WireMockRule defaultHttps = new WireMockRule(options().httpsPort(HTTPS_PORT));

    @Test
    public void canMakeHttpRequestWithDefaultSettings() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        defaultHttp.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpRequestWithCustomHostnameAndPort() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        customHttp.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.withOptions()
            .hostname(BIND_ADDRESS)
            .port(customHttp.port())
            .build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpRequestWithBasicAuth() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        defaultHttp.stubFor(get(urlPathEqualTo(path))
                .withBasicAuth(USERNAME, PASSWORD)
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.withOptions()
                .basicAuth(USERNAME, PASSWORD)
                .build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpsRequestWithSslNoVerify() throws Exception {
        final String path = "/api/hello";
        final String expectedResponseBody = "Hello, World";

        defaultHttps.stubFor(get(urlPathEqualTo(path))
                .willReturn(aResponse()
                        .withStatus(200)
                        .withBody(expectedResponseBody))
        );

        HttpClient httpClient = HttpClient.withOptions()
                .protocol(HttpClient.Protocol.HTTPS)
                .port(HTTPS_PORT)
                .sslNoVerify()
                .build();

        assertThat(httpClient.get(path)).isEqualTo(expectedResponseBody);
    }

    @Test
    public void canMakeHttpsRequestWithSslSelfSigned() throws Exception {
        // TODO: Setup fixtures for self-signed server cert, self-signed client cert, client private key, and self-signed CA cert
        // TODO: Setup WireMockRule with self-signed server cert
        // TODO: Create and test Kibana client with self-signed client cert, client private key, and self-signed CA cert
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
