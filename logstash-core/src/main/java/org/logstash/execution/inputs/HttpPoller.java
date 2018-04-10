package org.logstash.execution.inputs;

import java.nio.file.Path;
import java.util.Arrays;
import java.util.Collection;
import java.util.Map;
import org.logstash.execution.Input;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;
import org.logstash.execution.PluginConfigSpec;
import org.logstash.execution.QueueWriter;

public final class HttpPoller implements Input {

    private static final PluginConfigSpec<String> USER_CONFIG =
        LsConfiguration.stringSetting("user");

    private static final PluginConfigSpec<String> PASSWORD_CONFIG =
        LsConfiguration.stringSetting("password");

    private static final PluginConfigSpec<Long> AUTOMATIC_RETRIES_CONFIG =
        LsConfiguration.numSetting("automatic_retries", 1L);

    private static final PluginConfigSpec<Path> CA_CERT_CONFIG =
        LsConfiguration.pathSetting("cacert");

    private static final PluginConfigSpec<String> URL_METHOD_CONFIG =
        LsConfiguration.stringSetting("method");

    private static final PluginConfigSpec<Map<String, LsConfiguration>> URLS_CONFIG =
        LsConfiguration.requiredHashSetting(
            "urls", Arrays.asList(URL_METHOD_CONFIG, USER_CONFIG)
        );

    private final LsConfiguration configuration;

    public HttpPoller(final LsConfiguration configuration, final LsContext context) {
        this.configuration = configuration;
    }

    @Override
    public void start(final QueueWriter writer) {
        final String user = configuration.get(USER_CONFIG);
        final String password;
        if (configuration.contains(PASSWORD_CONFIG)) {
            //  password things
        } else {
            // no password things
        }
        final Map<String, LsConfiguration> urls = configuration.get(URLS_CONFIG);
        urls.forEach((key, config) -> {
            System.out.println("Schema on method " + key + " is " + config.get(URL_METHOD_CONFIG));
            System.out.println("User on method " + key + " is " + config.get(USER_CONFIG));
        });
    }

    @Override
    public void stop() {

    }

    @Override
    public void awaitStop() throws InterruptedException {

    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return Arrays.asList(
            USER_CONFIG, PASSWORD_CONFIG, AUTOMATIC_RETRIES_CONFIG, CA_CERT_CONFIG, URLS_CONFIG
        );
    }
}
