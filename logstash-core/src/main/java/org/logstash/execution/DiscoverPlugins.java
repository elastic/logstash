package org.logstash.execution;

import java.lang.reflect.Constructor;
import java.util.Set;
import org.reflections.Reflections;

/**
 * Quick demo of plugin discovery showing that the solution wouldn't require anything beyond
 * the plugin classes on the classpath.
 */
public final class DiscoverPlugins {

    public static void main(final String... args) throws NoSuchMethodException {
        Reflections reflections = new Reflections("org.logstash");
        Set<Class<?>> annotated = reflections.getTypesAnnotatedWith(LogstashPlugin.class);
        for (final Class<?> cls : annotated) {
            System.out.println(cls.getName());
            System.out.println(((LogstashPlugin) cls.getAnnotations()[0]).name());
            final Constructor<?> ctor = cls.getConstructor(LsConfiguration.class);
            System.out.println("Found Ctor at : " + ctor.getName());
            if (Filter.class.isAssignableFrom(cls)) {
                System.out.println("Filter");
            }
            if (Output.class.isAssignableFrom(cls)) {
                System.out.println("Output");
            }
            if (Input.class.isAssignableFrom(cls)) {
                System.out.println("Input");
            }
        }
    }
}
