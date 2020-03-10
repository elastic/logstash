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


package org.logstash.plugins.discovery;

import org.logstash.plugins.PluginLookup;
import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.Output;
import org.reflections.Reflections;

import java.lang.annotation.Annotation;
import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

/**
 * Registry for built-in Java plugins (not installed via logstash-plugin)
 */
public final class PluginRegistry {

    private static final Map<String, Class<Input>> INPUTS = new HashMap<>();
    private static final Map<String, Class<Filter>> FILTERS = new HashMap<>();
    private static final Map<String, Class<Output>> OUTPUTS = new HashMap<>();
    private static final Map<String, Class<Codec>> CODECS = new HashMap<>();

    static {
        discoverPlugins();
    }

    private PluginRegistry() {} // utility class

    @SuppressWarnings("unchecked")
    private static void discoverPlugins() {
        Reflections reflections = new Reflections("org.logstash.plugins");
        Set<Class<?>> annotated = reflections.getTypesAnnotatedWith(LogstashPlugin.class);
        for (final Class<?> cls : annotated) {
            for (final Annotation annotation : cls.getAnnotations()) {
                if (annotation instanceof LogstashPlugin) {
                    String name = ((LogstashPlugin) annotation).name();
                    if (Filter.class.isAssignableFrom(cls)) {
                        FILTERS.put(name, (Class<Filter>) cls);
                    }
                    if (Output.class.isAssignableFrom(cls)) {
                        OUTPUTS.put(name, (Class<Output>) cls);
                    }
                    if (Input.class.isAssignableFrom(cls)) {
                        INPUTS.put(name, (Class<Input>) cls);
                    }
                    if (Codec.class.isAssignableFrom(cls)) {
                        CODECS.put(name, (Class<Codec>) cls);
                    }

                    break;
                }
            }
        }
    }

    public static Class<?> getPluginClass(PluginLookup.PluginType pluginType, String pluginName) {
        if (pluginType == PluginLookup.PluginType.FILTER) {
            return getFilterClass(pluginName);
        }
        if (pluginType == PluginLookup.PluginType.OUTPUT) {
            return getOutputClass(pluginName);
        }
        if (pluginType == PluginLookup.PluginType.INPUT) {
            return getInputClass(pluginName);
        }
        if (pluginType == PluginLookup.PluginType.CODEC) {
            return getCodecClass(pluginName);
        }

        throw new IllegalStateException("Unknown plugin type: " + pluginType);

    }

    public static Class<Input> getInputClass(String name) {
        return INPUTS.get(name);
    }

    public static Class<Filter> getFilterClass(String name) {
        return FILTERS.get(name);
    }

    public static Class<Codec> getCodecClass(String name) {
        return CODECS.get(name);
    }

    public static Class<Output> getOutputClass(String name) {
        return OUTPUTS.get(name);
    }

    public static Codec getCodec(String name, Configuration configuration, Context context) {
        if (name != null && CODECS.containsKey(name)) {
            return instantiateCodec(CODECS.get(name), configuration, context);
        }
        return null;
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    private static Codec instantiateCodec(Class clazz, Configuration configuration, Context context) {
        try {
            Constructor<Codec> constructor = clazz.getConstructor(Configuration.class, Context.class);
            return constructor.newInstance(configuration, context);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to instantiate codec", e);
        }
    }
}
