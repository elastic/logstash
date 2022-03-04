/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package co.elastic.logstash.api;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Map;

/**
 * Utility methods for specifying common plugin config settings.
 */
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
     * @return Settings that are common to all input plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonInputSettings() {
        return Arrays.asList(ADD_FIELD_CONFIG, ENABLE_METRIC_CONFIG, CODEC_CONFIG,  ID_CONFIG,
                TAGS_CONFIG, TYPE_CONFIG);
    }

    /**
     * Combines the provided list of settings with the settings that are common to all input plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config settings.
     * @param settings provided list of settings.
     * @return combined list of settings.
     */
    public static Collection<PluginConfigSpec<?>> commonInputSettings(Collection<PluginConfigSpec<?>> settings) {
        return combineSettings(settings, commonInputSettings());
    }

    /**
     * @return Settings that are common to all output plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonOutputSettings() {
        return Arrays.asList(ENABLE_METRIC_CONFIG, CODEC_CONFIG, ID_CONFIG);
    }

    /**
     * Combines the provided list of settings with the settings that are common to all output plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config settings.
     * @param settings provided list of settings.
     * @return combined list of settings.
     */
    public static Collection<PluginConfigSpec<?>> commonOutputSettings(Collection<PluginConfigSpec<?>> settings) {
        return combineSettings(settings, commonOutputSettings());
    }

    /**
     * @return Settings that are common to all filter plugins.
     */
    public static Collection<PluginConfigSpec<?>> commonFilterSettings() {
        return Arrays.asList(ADD_FIELD_CONFIG, ADD_TAG_CONFIG, ENABLE_METRIC_CONFIG, ID_CONFIG,
                PERIODIC_FLUSH_CONFIG , REMOVE_FIELD_CONFIG, REMOVE_TAG_CONFIG);
    }

    /**
     * Combines the provided list of settings with the settings that are common to all filter plugins
     * ignoring any that are already present in the provided list. This allows plugins to override
     * defaults and other values on the common config settings.
     * @param settings provided list of settings.
     * @return combined list of settings.
     */
    public static Collection<PluginConfigSpec<?>> commonFilterSettings(Collection<PluginConfigSpec<?>> settings) {
        return combineSettings(settings, commonFilterSettings());
    }

    @SuppressWarnings("rawtypes")
    private static Collection<PluginConfigSpec<?>> combineSettings(
            Collection<PluginConfigSpec<?>> providedSettings,
            Collection<PluginConfigSpec<?>> commonSettings) {
        List<PluginConfigSpec<?>> settings = new ArrayList<>(providedSettings);
        for (PluginConfigSpec pcs : commonSettings) {
            if (!settings.contains(pcs)) {
                settings.add(pcs);
            }
        }
        return settings;
    }

}
