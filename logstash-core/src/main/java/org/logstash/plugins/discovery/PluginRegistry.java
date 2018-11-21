package org.logstash.plugins.discovery;

import java.lang.annotation.Annotation;
import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

import org.logstash.plugins.api.Codec;
import org.logstash.plugins.api.Filter;
import org.logstash.plugins.api.Input;
import org.logstash.plugins.api.LogstashPlugin;
import org.logstash.plugins.api.LsConfiguration;
import org.logstash.plugins.api.LsContext;
import org.logstash.plugins.api.Output;

/**
 * Logstash Java Plugin Registry.
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
        Reflections reflections = new Reflections("");
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

    public static Codec getCodec(String name, LsConfiguration configuration, LsContext context) {
        if (name != null && CODECS.containsKey(name)) {
            return instantiateCodec(CODECS.get(name), configuration, context);
        }
        return null;
    }

    private static Codec instantiateCodec(Class clazz, LsConfiguration configuration, LsContext context) {
        try {
            Constructor<Codec> constructor = clazz.getConstructor(LsConfiguration.class, LsContext.class);
            return constructor.newInstance(configuration, context);
        } catch (Exception e) {
            throw new IllegalStateException("Unable to instantiate codec", e);
        }
    }
}
