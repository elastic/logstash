package org.logstash.config.ir.compiler;

import java.util.HashMap;
import java.util.Map;

/**
 * Classloader capable of loading runtime compiled classes that were registered with it.
 */
final class DynamicClassLoader extends ClassLoader {

    /**
     * Map of classname to class for runtime compiled classes.
     */
    private final Map<String, Class<?>> cache = new HashMap<>();

    /**
     * Register a runtime compiled class with this classloader.
     * @param clazz Class to register
     */
    public void addClass(final Class<?> clazz) {
        cache.put(clazz.getName(), clazz);
    }

    @Override
    protected Class<?> findClass(String name) throws ClassNotFoundException {
        if (cache.containsKey(name)) {
            return cache.get(name);
        }
        return Thread.currentThread().getContextClassLoader().loadClass(name);
    }
}
