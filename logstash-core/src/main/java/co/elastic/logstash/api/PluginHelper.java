package co.elastic.logstash.api;

import org.apache.logging.log4j.Logger;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

public final class PluginHelper {

    public static final PluginConfigSpec<Map<String, String>> ADD_FIELD_CONFIG =
            Configuration.hashSetting("add_field");

    //public static final PluginConfigSpec<Array> ADD_TAG_CONFIG =
    //        Configuration.arraySetting("add_tag");

    public static final PluginConfigSpec<String> CODEC_CONFIG =
            Configuration.stringSetting("codec");

    public static final PluginConfigSpec<Boolean> ENABLE_METRIC_CONFIG =
            Configuration.booleanSetting("enable_metric");

    public static final PluginConfigSpec<String> ID_CONFIG =
            Configuration.stringSetting("id");

    public static final PluginConfigSpec<Boolean> PERIODIC_FLUSH_CONFIG =
            Configuration.booleanSetting("periodic_flush");

    //public static final PluginConfigSpec<Array> REMOVE_FIELD_CONFIG =
    //        Configuration.arraySetting("remove_field");

    //public static final PluginConfigSpec<Array> REMOVE_TAG_CONFIG =
    //        Configuration.arraySetting("remove_tag");

    //public static final PluginConfigSpec<Array> TAGS_CONFIG =
    //        Configuration.arraySetting("tags");

    public static final PluginConfigSpec<String> TYPE_CONFIG =
            Configuration.stringSetting("type");


    /**
     * Returns a list of the options that are common to all input plugins.
     */
    @SuppressWarnings("unchecked")
    public static Collection<PluginConfigSpec<?>> commonInputOptions() {
        return commonInputOptions(Collections.EMPTY_LIST);
    }

    /**
     * Combines the provided list of options with the options that are common to all input plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     */
    public static Collection<PluginConfigSpec<?>> commonInputOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, Arrays.asList(ADD_FIELD_CONFIG, ENABLE_METRIC_CONFIG,
                CODEC_CONFIG,  ID_CONFIG, /*TAGS_CONFIG,*/ TYPE_CONFIG));
    }

    /**
     * Returns a list of the options that are common to all output plugins.
     */
    @SuppressWarnings("unchecked")
    public static Collection<PluginConfigSpec<?>> commonOutputOptions() {
        return commonOutputOptions(Collections.EMPTY_LIST);
    }

    /**
     * Combines the provided list of options with the options that are common to all output plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     */
    public static Collection<PluginConfigSpec<?>> commonOutputOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, Arrays.asList(ENABLE_METRIC_CONFIG, CODEC_CONFIG,  ID_CONFIG));
    }

    /**
     * Returns a list of the options that are common to all filter plugins.
     */
    @SuppressWarnings("unchecked")
    public static Collection<PluginConfigSpec<?>> commonFilterOptions() {
        return commonFilterOptions(Collections.EMPTY_LIST);
    }

    /**
     * Combines the provided list of options with the options that are common to all filter plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     */
    public static Collection<PluginConfigSpec<?>> commonFilterOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, Arrays.asList(ADD_FIELD_CONFIG, /*ADD_TAG_CONFIG,*/
                ENABLE_METRIC_CONFIG, ID_CONFIG, PERIODIC_FLUSH_CONFIG /*, REMOVE_FIELD_CONFIG,
                REMOVE_TAG_CONFIG*/));
    }

    @SuppressWarnings("rawtypes")
    private static Collection<PluginConfigSpec<?>> combineOptions(
            Collection<PluginConfigSpec<?>> providedOptions,
            Collection<PluginConfigSpec<?>> commonOptions) {
        List<PluginConfigSpec<?>> options = new ArrayList<>();
        options.addAll(providedOptions);
        for (PluginConfigSpec pcs : commonOptions) {
            if (!options.contains(pcs)) {
                options.add(pcs);
            }
        }
        return options;
    }

    public static void validateConfig(Plugin plugin, Logger logger, Configuration config) {
        List<String> configErrors = new ArrayList<>();

        List<String> configSchemaNames = plugin.configSchema().stream().map(PluginConfigSpec::name)
                .collect(Collectors.toList());

        // find config options that are invalid for the specified plugin
        Collection<String> providedConfig = config.allKeys();
        for (String configKey : providedConfig) {
            if (!configSchemaNames.contains(configKey)) {
                configErrors.add(String.format("Unknown config option '%s' specified for plugin '%s'",
                        configKey, plugin.getName()));
            }
        }

        // find required config options that are missing
        for (PluginConfigSpec<?> configSpec : plugin.configSchema()) {
            if (configSpec.required() && !providedConfig.contains(configSpec.name())) {
                configErrors.add(String.format("Required config option '%s' not specified for plugin '%s'",
                        configSpec.name(), plugin.getName()));
            }
        }

        if (configErrors.size() > 0) {
            for (String err : configErrors) {
                logger.error(err);
            }
            throw new IllegalStateException("Config errors found for plugin '" + plugin.getName() + "'");
        }
    }

    public static String pluginName(Plugin plugin) {
        LogstashPlugin annotation = plugin.getClass().getDeclaredAnnotation(LogstashPlugin.class);
        return (annotation.name() != null && !annotation.name().equals(""))
                ? annotation.name()
                : plugin.getClass().getName();
    }

    public static String pluginId(Plugin plugin) {
        return plugin.getName() + "_" + UUID.randomUUID().toString();
    }

}
