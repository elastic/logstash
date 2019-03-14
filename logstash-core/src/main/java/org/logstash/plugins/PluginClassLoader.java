package org.logstash.plugins;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Classloader for Java plugins to isolate their dependencies. Will not load any classes in the
 * <code>co.elastic.logstash</code> or <code>org.logstash</code> packages to avoid the possibility
 * of clashes with classes in Logstash core.
 */
public class PluginClassLoader extends URLClassLoader {

    private ClassLoader appClassLoader;

    private PluginClassLoader(URL[] urls, ClassLoader appClassLoader) {
        super(urls, null);
        this.appClassLoader = appClassLoader;
    }

    /**
     * Creates an instance of the plugin classloader.
     * @param gemPath Path to the Ruby gem containing the Java plugin as reported by
     *                <code>Gem::BasicSpecification#loaded_from</code>.
     * @param jarPath Path to the Java plugin's JAR file relative to {@code gemPath}.
     * @param appClassLoader Application classloader to be used for classes not found
     *                       in the plugin's JAR file.
     * @return New instance of the plugin classloader.
     */
    public static PluginClassLoader create(String gemPath, String jarPath, ClassLoader appClassLoader) {
        String pluginPath = gemPath.substring(0, gemPath.lastIndexOf(File.separator)) + File.separator + jarPath;
        Path pluginJar = Paths.get(pluginPath);
        if (!Files.exists(pluginJar)) {
            throw new IllegalStateException("PluginClassLoader unable to locate jar file: " + pluginPath);
        }
        try {
            URL[] pluginJarUrl = new URL[]{pluginJar.toUri().toURL()};
            return new PluginClassLoader(pluginJarUrl, appClassLoader);
        } catch (MalformedURLException e) {
            throw new IllegalStateException(e);
        }
    }

    @Override
    protected Class<?> loadClass(String name, boolean resolve) throws ClassNotFoundException {
        synchronized (getClassLoadingLock(name)) {
            Class<?> c = findLoadedClass(name);
            if (!name.startsWith("co.elastic.logstash.") && !name.startsWith("org.logstash.")) {
                if (c == null) {
                    try {
                        c = findClass(name);
                    } catch (ClassNotFoundException e) {
                        c = super.loadClass(name, resolve);
                    }
                }
            } else {
                c = appClassLoader.loadClass(name);
            }
            if (resolve) {
                resolveClass(c);
            }
            return c;
        }
    }
}
