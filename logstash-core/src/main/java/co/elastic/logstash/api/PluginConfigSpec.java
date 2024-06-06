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

import java.net.URI;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Plugin configuration specification. Allows the name, type, deprecation status, required status, and default
 * value for each configuration setting to be defined.
 * @param <T> The expected type of the setting value.
 */
public final class PluginConfigSpec<T> {

    private ConfigData<T> configData;

    private String rawDefaultValue;


    private PluginConfigSpec(final ConfigData<T> configData) {
        this.configData = configData;
    }

    public static PluginConfigSpec<String> stringSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, String.class, null, false, false));
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String defaultValue) {
        return new PluginConfigSpec<>(new ConfigData<>(name, String.class, defaultValue, false, false));
    }

    public static PluginConfigSpec<String> requiredStringSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, String.class, null, false, true));
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(new ConfigData<>(name, String.class, defaultValue, deprecated, required));
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Codec.class, null, false, false));
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name, final String defaultCodecName) {
        PluginConfigSpec<Codec> pcs = new PluginConfigSpec<>(new ConfigData<>(name, Codec.class, null, false, false));
        pcs.rawDefaultValue = defaultCodecName;
        return pcs;
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name, final Codec defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Codec.class, defaultValue, deprecated, required));
    }

    public static PluginConfigSpec<URI> uriSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, URI.class, null, false, false));
    }

    public static PluginConfigSpec<URI> uriSetting(final String name, final String defaultUri) {
        PluginConfigSpec<URI> pcs = new PluginConfigSpec<>(new ConfigData<>(name, URI.class, null, false, false));
        pcs.rawDefaultValue = defaultUri;
        return pcs;
    }

    public static PluginConfigSpec<URI> uriSetting(final String name, final String defaultUri, boolean deprecated, boolean required) {
        PluginConfigSpec<URI> pcs = new PluginConfigSpec<>(new ConfigData<>(name, URI.class, null, deprecated, required));
        pcs.rawDefaultValue = defaultUri;
        return pcs;
    }

    public static PluginConfigSpec<Long> numSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Long.class, null, false, false));
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Long.class, defaultValue, false, false));
    }

    public static PluginConfigSpec<Double> floatSetting(final String name, final double defaultValue) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Double.class, defaultValue, false, false));
    }

    public static PluginConfigSpec<Double> floatSetting(final String name, final double defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Double.class, defaultValue, deprecated, required));
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Long.class, defaultValue, deprecated, required));
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Boolean.class, null, false, false));
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name, final boolean defaultValue) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Boolean.class, defaultValue, false, false));
    }

    public static PluginConfigSpec<Boolean> requiredBooleanSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Boolean.class, null, false, true));
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name, final boolean defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Boolean.class, defaultValue, deprecated, required));
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, Object>> hashSetting(final String name) {
        return new PluginConfigSpec(new ConfigData<>(name, Map.class, null, false, false));
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, Object>> hashSetting(final String name, Map<String, Object> defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec(new ConfigData<>(name, Map.class, defaultValue, deprecated, required));
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<List<Object>> arraySetting(final String name) {
        return new PluginConfigSpec(new ConfigData<>(name, List.class, null, false, false));
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<List<Object>> arraySetting(final String name, List<Object> defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec(new ConfigData<>(name, List.class, defaultValue, deprecated, required));
    }

    public static PluginConfigSpec<Password> passwordSetting(final String name) {
        return new PluginConfigSpec<>(new ConfigData<>(name, Password.class, null, false, false));
    }

    public static PluginConfigSpec<Password> passwordSetting(final String name, final String defaultValue, boolean deprecated, boolean required) {
        PluginConfigSpec<Password> pcs = new PluginConfigSpec<>(new ConfigData<>(name, Password.class, null, false, false));
        pcs.rawDefaultValue = defaultValue;
        return pcs;
    }

    public Collection<PluginConfigSpec<?>> children() {
        return configData.children;
    }

    public boolean deprecated() {
        return this.configData.deprecated;
    }

    public boolean required() {
        return this.configData.required;
    }

    public T defaultValue() {
        return this.configData.defaultValue;
    }

    public String name() {
        return configData.name;
    }

    public Class<T> type() {
        return configData.type;
    }

    public String getRawDefaultValue() {
        return rawDefaultValue;
    }
}
