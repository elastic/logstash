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

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.plugins.AliasRegistry;
import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.Output;
import org.logstash.plugins.PluginLookup.PluginType;
import org.reflections.Reflections;
import org.reflections.util.ClasspathHelper;
import org.reflections.util.ConfigurationBuilder;

import java.lang.annotation.Annotation;
import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Registry for built-in Java plugins (not installed via logstash-plugin).
 * This is singleton ofr two reasons:
 * <ul>
 *  <li>it's a registry so no need for multiple instances</li>
 *  <li>the Reflections library used need to run in single thread during discovery phase</li>
 * </ul>
 * */
public final class PluginRegistry {

    private static final Logger LOGGER = LogManager.getLogger(PluginRegistry.class);

    private final Map<String, Class<Input>> inputs = new HashMap<>();
    private final Map<String, Class<Filter>> filters = new HashMap<>();
    private final Map<String, Class<Output>> outputs = new HashMap<>();
    private final Map<String, Class<Codec>> codecs = new HashMap<>();
    private static final Object LOCK = new Object();
    private static volatile PluginRegistry INSTANCE;
    private final AliasRegistry aliasRegistry = AliasRegistry.getInstance();

    private PluginRegistry() {
        discoverPlugins();
    }

    public static PluginRegistry getInstance() {
        if (INSTANCE == null) {
            synchronized (LOCK) {
                if (INSTANCE == null) {
                    INSTANCE = new PluginRegistry();
                }
            }
        }
        return INSTANCE;
    }
    
    @SuppressWarnings("unchecked")
    private void discoverPlugins() {
        // the constructor of Reflection must be called only by one thread, else there is a
        // risk that the first thread that completes close the Zip files for the others.
        // scan all .class present in package classpath
        final ConfigurationBuilder configurationBuilder = new ConfigurationBuilder()
                .setUrls(ClasspathHelper.forPackage("org.logstash.plugins"))
                .filterInputsBy(input -> input.endsWith(".class"));
        Reflections reflections = new Reflections(configurationBuilder);

        Set<Class<?>> annotated = reflections.getTypesAnnotatedWith(LogstashPlugin.class);
        for (final Class<?> cls : annotated) {
            for (final Annotation annotation : cls.getAnnotations()) {
                if (annotation instanceof LogstashPlugin) {
                    String name = ((LogstashPlugin) annotation).name();
                    if (Filter.class.isAssignableFrom(cls)) {
                        filters.put(name, (Class<Filter>) cls);
                    }
                    if (Output.class.isAssignableFrom(cls)) {
                        outputs.put(name, (Class<Output>) cls);
                    }
                    if (Input.class.isAssignableFrom(cls)) {
                        inputs.put(name, (Class<Input>) cls);
                    }
                    if (Codec.class.isAssignableFrom(cls)) {
                        codecs.put(name, (Class<Codec>) cls);
                    }

                    break;
                }
            }
        }

        // after loaded all plugins, check if aliases has to be provided
        addAliasedPlugins(PluginType.FILTER, filters);
        addAliasedPlugins(PluginType.OUTPUT, outputs);
        addAliasedPlugins(PluginType.INPUT, inputs);
        addAliasedPlugins(PluginType.CODEC, codecs);
    }

    private <T> void addAliasedPlugins(PluginType type, Map<String, Class<T>> pluginCache) {
        final Map<String, Class<T>> aliasesToAdd = new HashMap<>();
        for (Map.Entry<String, Class<T>> e : pluginCache.entrySet()) {
            final String realPluginName = e.getKey();
            final Optional<String> alias = aliasRegistry.aliasFromOriginal(type, realPluginName);
            if (alias.isPresent()) {
                final String aliasName = alias.get();
                if (!pluginCache.containsKey(aliasName)) {
                    // no real plugin with same alias name was found
                    aliasesToAdd.put(aliasName, e.getValue());
                    final String typeStr = type.name().toLowerCase();
                    LOGGER.info("Plugin {}-{} is aliased as {}-{}", typeStr, realPluginName, typeStr, aliasName);
                }
            }
        }
        for (Map.Entry<String, Class<T>> e : aliasesToAdd.entrySet()) {
            pluginCache.put(e.getKey(), e.getValue());
        }
    }

    public Class<?> getPluginClass(PluginType pluginType, String pluginName) {
        
        switch (pluginType) {
            case FILTER:
                return getFilterClass(pluginName);
            case OUTPUT:
                return getOutputClass(pluginName);
            case INPUT:
                return getInputClass(pluginName);
            case CODEC:
                return getCodecClass(pluginName);
            default:
                throw new IllegalStateException("Unknown plugin type: " + pluginType);
        }
    }

    public Class<Input> getInputClass(String name) {
        return inputs.get(name);
    }

    public Class<Filter> getFilterClass(String name) {
        return filters.get(name);
    }

    public Class<Codec> getCodecClass(String name) {
        return codecs.get(name);
    }

    public Class<Output> getOutputClass(String name) {
        return outputs.get(name);
    }

    public Codec getCodec(String name, Configuration configuration, Context context) {
        if (name != null && codecs.containsKey(name)) {
            return instantiateCodec(codecs.get(name), configuration, context);
        }
        return null;
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    private Codec instantiateCodec(Class clazz, Configuration configuration, Context context) {
        try {
            Constructor<Codec> constructor = clazz.getConstructor(Configuration.class, Context.class);
            return constructor.newInstance(configuration, context);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to instantiate codec", e);
        }
    }
}
