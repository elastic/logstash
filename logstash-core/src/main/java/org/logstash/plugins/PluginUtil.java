package org.logstash.plugins;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Plugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;
import com.google.common.annotations.VisibleForTesting;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

public class PluginUtil {

    private PluginUtil() { /* utility methods */ }

    private static final Logger LOGGER = LogManager.getLogger(PluginHelper.class);

    public static void validateConfig(Plugin plugin, Configuration config) {
        List<String> configErrors = doValidateConfig(plugin, config);
        if (configErrors.size() > 0) {
            for (String err : configErrors) {
                LOGGER.error(err);
            }
            throw new IllegalStateException("Config errors found for plugin '" + plugin.getName() + "'");
        }
    }

    @VisibleForTesting
    public static List<String> doValidateConfig(Plugin plugin, Configuration config) {
        List<String> configErrors = new ArrayList<>();

        List<String> configSchemaNames = plugin.configSchema().stream().map(PluginConfigSpec::name)
                .collect(Collectors.toList());

        // find config options that are invalid for the specified plugin
        Collection<String> providedConfig = config.allKeys();
        for (String configKey : providedConfig) {
            if (!configSchemaNames.contains(configKey)) {
                configErrors.add(String.format("Unknown setting '%s' specified for plugin '%s'",
                        configKey, plugin.getName()));
            }
        }

        // find required config options that are missing
        for (PluginConfigSpec<?> configSpec : plugin.configSchema()) {
            if (configSpec.required() && !providedConfig.contains(configSpec.name())) {
                configErrors.add(String.format("Required setting '%s' not specified for plugin '%s'",
                        configSpec.name(), plugin.getName()));
            }
        }

        return configErrors;
    }
}
