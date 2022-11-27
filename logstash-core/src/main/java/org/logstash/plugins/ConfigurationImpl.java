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


package org.logstash.plugins;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Password;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.Codec;
import org.jruby.RubyObject;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.plugins.factory.RubyCodecDelegator;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Collection;
import java.util.Map;

/**
 * Configuration for Logstash Java plugins.
 */
public final class ConfigurationImpl implements Configuration {

    private final RubyIntegration.PluginFactory pluginFactory;
    private final Map<String, Object> rawSettings;

    /**
     * @param raw           Configuration settings map. Values are serialized.
     * @param pluginFactory Plugin factory for resolving default codecs by name.
     */
    public ConfigurationImpl(final Map<String, Object> raw, RubyIntegration.PluginFactory pluginFactory) {
        this.pluginFactory = pluginFactory;
        this.rawSettings = raw;
    }

    /**
     * @param raw Configuration Settings Map. Values are serialized.
     */
    public ConfigurationImpl(final Map<String, Object> raw) {
        this(raw, null);
    }

    @Override
    @SuppressWarnings("unchecked")
    public <T> T get(final PluginConfigSpec<T> configSpec) {
        if (rawSettings.containsKey(configSpec.name())) {
            Object o = rawSettings.get(configSpec.name());
            if (configSpec.type().isAssignableFrom(o.getClass())) {
                return (T) o;
            } else if (configSpec.type() == Double.class && o.getClass() == Long.class) {
                return configSpec.type().cast(((Long)o).doubleValue());
            } else if (configSpec.type() == Boolean.class && o instanceof String) {
                return configSpec.type().cast(Boolean.parseBoolean((String) o));
            } else if (configSpec.type() == Codec.class && o instanceof String && pluginFactory != null) {
                Codec codec = pluginFactory.buildDefaultCodec((String) o);
                return configSpec.type().cast(codec);
            } else if (configSpec.type() == Codec.class && o instanceof RubyObject && RubyCodecDelegator.isRubyCodecSubclass((RubyObject) o)) {
                Codec codec = pluginFactory.buildRubyCodecWrapper((RubyObject) o);
                return configSpec.type().cast(codec);
            } else if (configSpec.type() == URI.class && o instanceof String) {
                try {
                    URI uri = new URI((String) o);
                    return configSpec.type().cast(uri);
                } catch (URISyntaxException ex) {
                    throw new IllegalStateException(
                            String.format("Invalid URI specified for '%s'", configSpec.name()));
                }
            } else if (configSpec.type() == Password.class && o instanceof String) {
                Password p = new Password((String) o);
                return configSpec.type().cast(p);
            } else {
                throw new IllegalStateException(
                        String.format("Setting value for '%s' of type '%s' incompatible with defined type of '%s'",
                                configSpec.name(), o.getClass(), configSpec.type()));
            }
        } else if (configSpec.type() == Codec.class && configSpec.getRawDefaultValue() != null && pluginFactory != null) {
            Codec codec = pluginFactory.buildDefaultCodec(configSpec.getRawDefaultValue());
            return configSpec.type().cast(codec);
        } else if (configSpec.type() == URI.class && configSpec.getRawDefaultValue() != null) {
            try {
                URI uri = new URI(configSpec.getRawDefaultValue());
                return configSpec.type().cast(uri);
            } catch (URISyntaxException ex) {
                throw new IllegalStateException(
                        String.format("Invalid default URI specified for '%s'", configSpec.name()));
            }
        } else if (configSpec.type() == Password.class && configSpec.getRawDefaultValue() != null) {
            Password p = new Password(configSpec.getRawDefaultValue());
            return configSpec.type().cast(p);
        } else {
            return configSpec.defaultValue();
        }
    }

    @Override
    public Object getRawValue(final PluginConfigSpec<?> configSpec) {
        return rawSettings.get(configSpec.name());
    }

    @Override
    public boolean contains(final PluginConfigSpec<?> configSpec) {
        return rawSettings.containsKey(configSpec.name());
    }

    @Override
    public Collection<String> allKeys() {
        return rawSettings.keySet();
    }
}
