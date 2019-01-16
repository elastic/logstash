package co.elastic.logstash.api;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;

public final class PluginHelper {

    public static final PluginConfigSpec<Map<String, Object>> ADD_FIELD_CONFIG =
            PluginConfigSpec.hashSetting("add_field");

    public static final PluginConfigSpec<List<Object>> ADD_TAG_CONFIG =
            PluginConfigSpec.arraySetting("add_tag");

    public static final PluginConfigSpec<Codec> CODEC_CONFIG =
            PluginConfigSpec.codecSetting("codec");

    public static final PluginConfigSpec<Boolean> ENABLE_METRIC_CONFIG =
            PluginConfigSpec.booleanSetting("enable_metric");

    public static final PluginConfigSpec<String> ID_CONFIG =
            PluginConfigSpec.stringSetting("id");

    public static final PluginConfigSpec<Boolean> PERIODIC_FLUSH_CONFIG =
            PluginConfigSpec.booleanSetting("periodic_flush");

    public static final PluginConfigSpec<List<Object>> REMOVE_FIELD_CONFIG =
            PluginConfigSpec.arraySetting("remove_field");

    public static final PluginConfigSpec<List<Object>> REMOVE_TAG_CONFIG =
            PluginConfigSpec.arraySetting("remove_tag");

    public static final PluginConfigSpec<List<Object>> TAGS_CONFIG =
            PluginConfigSpec.arraySetting("tags");

    public static final PluginConfigSpec<String> TYPE_CONFIG =
            PluginConfigSpec.stringSetting("type");


    /**
     * @return Options that are common to all input plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonInputOptions() {
        return Arrays.asList(ADD_FIELD_CONFIG, ENABLE_METRIC_CONFIG, CODEC_CONFIG,  ID_CONFIG,
                TAGS_CONFIG, TYPE_CONFIG);
    }

    /**
     * Combines the provided list of options with the options that are common to all input plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     * @param options provided list of options.
     * @return combined list of options.
     */
    public static Collection<PluginConfigSpec<?>> commonInputOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, commonInputOptions());
    }

    /**
     * @return Options that are common to all output plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonOutputOptions() {
        return Arrays.asList(ENABLE_METRIC_CONFIG, CODEC_CONFIG, ID_CONFIG);
    }

    /**
     * Combines the provided list of options with the options that are common to all output plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     * @param options provided list of options.
     * @return combined list of options.
     */
    public static Collection<PluginConfigSpec<?>> commonOutputOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, commonOutputOptions());
    }

    /**
     * @return Options that are common to all filter plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonFilterOptions() {
        return Arrays.asList(ADD_FIELD_CONFIG, ADD_TAG_CONFIG, ENABLE_METRIC_CONFIG, ID_CONFIG,
                PERIODIC_FLUSH_CONFIG , REMOVE_FIELD_CONFIG, REMOVE_TAG_CONFIG);
    }

    /**
     * Combines the provided list of options with the options that are common to all filter plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config options.
     * @param options provided list of options.
     * @return combined list of options.
     */
    public static Collection<PluginConfigSpec<?>> commonFilterOptions(Collection<PluginConfigSpec<?>> options) {
        return combineOptions(options, commonFilterOptions());
    }

    @SuppressWarnings("rawtypes")
    private static Collection<PluginConfigSpec<?>> combineOptions(
            Collection<PluginConfigSpec<?>> providedOptions,
            Collection<PluginConfigSpec<?>> commonOptions) {
        List<PluginConfigSpec<?>> options = new ArrayList<>(providedOptions);
        for (PluginConfigSpec pcs : commonOptions) {
            if (!options.contains(pcs)) {
                options.add(pcs);
            }
        }
        return options;
    }

}
