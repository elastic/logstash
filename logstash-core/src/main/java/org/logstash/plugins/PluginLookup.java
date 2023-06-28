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

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.Output;
import co.elastic.logstash.api.Plugin;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.javasupport.JavaClass;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.plugins.discovery.PluginRegistry;
import org.logstash.plugins.factory.PluginFactoryExt;

import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Java Implementation of the plugin that is implemented by wrapping the Ruby
 * {@code LogStash::Plugin} class for the Ruby plugin lookup.
 */
public final class PluginLookup implements PluginFactoryExt.PluginResolver {

    private static final String INPUT_PLUGIN_TYPE_NAME = "input";
    private static final String FILTER_PLUGIN_TYPE_NAME = "filter";
    private static final String OUTPUT_PLUGIN_TYPE_NAME = "output";
    private static final String CODEC_PLUGIN_TYPE_NAME = "codec";

    private static final IRubyObject RUBY_REGISTRY = RubyUtil.RUBY.executeScript(
            "require 'logstash/plugins/registry'\nrequire 'logstash/plugin'\nLogStash::Plugin",
            ""
    );

    private final PluginRegistry pluginRegistry;

    public PluginLookup(PluginRegistry pluginRegistry) {
        this.pluginRegistry = pluginRegistry;
    }

    @SuppressWarnings("rawtypes")
    @Override
    public PluginClass resolve(PluginType type, String name) {
        Class<?> javaClass = pluginRegistry.getPluginClass(type, name);
        if (javaClass != null) {

            if (!PluginValidator.validatePlugin(type, javaClass)) {
                throw new IllegalStateException("Java plugin '" + name + "' is incompatible with the current Logstash plugin API");
            }

            return new PluginLookup.PluginClass() {

                @Override
                public PluginLookup.PluginLanguage language() {
                    return PluginLookup.PluginLanguage.JAVA;
                }

                @Override
                public Object klass() {
                    return javaClass;
                }
            };
        } else {
            Object klass =
                    RUBY_REGISTRY.callMethod(
                            RubyUtil.RUBY.getCurrentContext(), "lookup",
                            new IRubyObject[]{type.rubyLabel(), RubyUtil.RUBY.newString(name)});

            PluginLanguage language = klass instanceof RubyClass
                    ? PluginLanguage.RUBY
                    : PluginLanguage.JAVA;

            klass = (klass instanceof JavaProxy) ? ((JavaProxy) klass).getObject() : klass;

            Object resolvedClass = klass instanceof java.lang.Class
                    ? ((java.lang.Class) klass)
                    : klass;

            if (language == PluginLanguage.JAVA && !PluginValidator.validatePlugin(type, (Class) resolvedClass)) {
                throw new IllegalStateException("Java plugin '" + name + "' is incompatible with the current Logstash plugin API");
            }

            return new PluginLookup.PluginClass() {
                @Override
                public PluginLookup.PluginLanguage language() {
                    return language;
                }

                @Override
                public Object klass() {
                    return resolvedClass;
                }
            };
        }
    }

    /**
     * Descriptor of a plugin implementation. Defines the implementation language and the plugin class
     * */
    public interface PluginClass {
        PluginLookup.PluginLanguage language();

        Object klass();

        default String toReadableString() {
            return String.format("Plugin class [%s], language [%s]", klass(), language());
        }
    }

    /**
     * Enum all the implementation languages used by plugins
     * */
    public enum PluginLanguage {
        JAVA, RUBY
    }

    /**
     * Enum all the plugins types used inside Logstash
     * */
    public enum PluginType {

        @JsonProperty(INPUT_PLUGIN_TYPE_NAME)
        INPUT(INPUT_PLUGIN_TYPE_NAME, "inputs", Input.class),

        @JsonProperty(FILTER_PLUGIN_TYPE_NAME)
        FILTER(FILTER_PLUGIN_TYPE_NAME, "filters", Filter.class),

        @JsonProperty(OUTPUT_PLUGIN_TYPE_NAME)
        OUTPUT(OUTPUT_PLUGIN_TYPE_NAME, "outputs", Output.class),

        @JsonProperty(CODEC_PLUGIN_TYPE_NAME)
        CODEC(CODEC_PLUGIN_TYPE_NAME, "codecs", Codec.class);

        private final RubyString rubyLabel;
        private final String metricNamespace;
        private final Class<? extends Plugin> pluginClass;

        PluginType(final String label, final String metricNamespace, final Class<? extends Plugin> pluginClass) {
            this.rubyLabel = RubyUtil.RUBY.newString(label);
            this.metricNamespace = metricNamespace;
            this.pluginClass = pluginClass;
        }

        public RubyString rubyLabel() {
            return rubyLabel;
        }

        public String metricNamespace() {
            return metricNamespace;
        }

        public Class<? extends Plugin> pluginClass() {
            return pluginClass;
        }

        public static PluginType getTypeByPlugin(Plugin plugin) {
            for (final PluginType type : PluginType.values()) {
                if (type.pluginClass().isInstance(plugin)) {
                    return type;
                }
            }

            final String allowedPluginTypes = Stream.of(PluginType.values())
                .map((t) -> t.pluginClass().getName()).collect(Collectors.joining(", "));

            throw new IllegalArgumentException(String.format(
                "Plugin [%s] does not extend one of: %s",
                plugin.getName(),
                allowedPluginTypes
            ));
        }
    }
}
