package org.logstash.common.kibana;

import com.github.tomakehurst.wiremock.junit.WireMockRule;
import org.junit.Rule;
import org.junit.Test;

import static com.github.tomakehurst.wiremock.client.WireMock.aResponse;
import static com.github.tomakehurst.wiremock.client.WireMock.head;
import static com.github.tomakehurst.wiremock.client.WireMock.urlPathEqualTo;
import static com.github.tomakehurst.wiremock.core.WireMockConfiguration.options;
import static org.assertj.core.api.Assertions.assertThat;

public class ClientTest {

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
    public void canConnectWithDefaultSettings() throws Exception {
        final String path = "/api/status";
        defaultHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }

    @Test
    public void canConnectWithCustomUrl() throws Exception {
        final String path = "/api/status";
        customHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.withOptions()
            .protocol(Client.Protocol.HTTP)
            .hostname(BIND_ADDRESS)
            .port(customHttp.port())
            .build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }

    @Test
    public void canConnectWithBasicAuth() throws Exception {
        final String path = "/api/status";
        defaultHttp.stubFor(head(urlPathEqualTo(path))
                .withBasicAuth(USERNAME, PASSWORD)
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.withOptions()
                .basicAuth(USERNAME, PASSWORD)
                .build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }

    @Test
    public void canConnectWithDefaultSsl() throws Exception {
        final String path = "/api/status";
        defaultHttps.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.withOptions()
                .protocol(Client.Protocol.HTTPS)
                .port(HTTPS_PORT)
                .sslNoVerify()
                .build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }

    @Test
    public void canConnectWithCustomSsl() throws Exception {
        // TODO: Setup fixtures for self-signed server cert, self-signed client cert, client private key, and self-signed CA cert
        // TODO: Setup WireMockRule with self-signed server cert
        // TODO: Create and test Kibana client with self-signed client cert, client private key, and self-signed CA cert
    }
}
