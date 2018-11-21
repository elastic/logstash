package org.logstash.plugins.api;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

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

}
