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
        final String path = "/api/status";
        defaultHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        HttpClient httpClient = HttpClient.build();
        httpClient.head(path);
    }

    @Test
    public void canMakeHttpRequestWithCustomHostnameAndPort() throws Exception {
        final String path = "/api/status";
        customHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        HttpClient httpClient = HttpClient.withOptions()
            .hostname(BIND_ADDRESS)
            .port(customHttp.port())
            .build();
        httpClient.head(path);
    }

    @Test
    public void canMakeHttpRequestWithBasicAuth() throws Exception {
        final String path = "/api/status";
        defaultHttp.stubFor(head(urlPathEqualTo(path))
                .withBasicAuth(USERNAME, PASSWORD)
                .willReturn(aResponse().withStatus(200)));

        HttpClient httpClient = HttpClient.withOptions()
                .basicAuth(USERNAME, PASSWORD)
                .build();
        httpClient.head(path);
    }

    @Test
    public void canMakeHttpsRequestWithSslNoVerify() throws Exception {
        final String path = "/api/status";
        defaultHttps.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        HttpClient httpClient = HttpClient.withOptions()
                .protocol(HttpClient.Protocol.HTTPS)
                .port(HTTPS_PORT)
                .sslNoVerify()
                .build();
        httpClient.head(path);
    }

    @Test
    public void canMakeHttpsRequestWithSslSelfSigned() throws Exception {
        // TODO: Setup fixtures for self-signed server cert, self-signed client cert, client private key, and self-signed CA cert
        // TODO: Setup WireMockRule with self-signed server cert
        // TODO: Create and test Kibana client with self-signed client cert, client private key, and self-signed CA cert
    }
}
