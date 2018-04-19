package org.logstash.execution.plugins.discovery;

import java.lang.annotation.Annotation;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import org.logstash.execution.LogstashPlugin;

/**
 * Logstash Java Plugin Discovery.
 */
public final class DiscoverPlugins {

    public static Map<String, Class<?>> discoverPlugins() {
        Reflections reflections = new Reflections("");
        Set<Class<?>> annotated = reflections.getTypesAnnotatedWith(LogstashPlugin.class);
        final Map<String, Class<?>> results = new HashMap<>();
        for (final Class<?> cls : annotated) {
            for (final Annotation annotation : cls.getAnnotations()) {
                if (annotation instanceof LogstashPlugin) {
                    results.put(((LogstashPlugin) annotation).name(), cls);
                    break;
                }
            }
        }
        return results;
    }
}
