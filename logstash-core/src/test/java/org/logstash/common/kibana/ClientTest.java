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

    @Rule
    public WireMockRule defaultHttp = new WireMockRule(5601);

    @Rule
    public WireMockRule customHttp = new WireMockRule(options().dynamicPort().bindAddress("127.0.0.1"));

    @Test
    public void canConnectWithDefaultSettings() throws Exception {
        final String path = "/api/status";
        defaultHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.options().build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }

    @Test
    public void canConnectWithCustomUrl() throws Exception {
        final String path = "/api/status";
        customHttp.stubFor(head(urlPathEqualTo(path))
                .willReturn(aResponse().withStatus(200)));

        Client kibanaClient = Client.options()
            .withProtocol(Client.Builder.Protocol.HTTP)
            .withHostname("127.0.0.1")
            .withPort(customHttp.port())
            .build();
        assertThat(kibanaClient.canConnect()).isTrue();
    }
}
