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
     * @param jarPath Full path to the Java plugin's JAR file.
     * @param appClassLoader Application classloader to be used for classes not found
     *                       in the plugin's JAR file.
     * @return New instance of the plugin classloader.
     */
    public static PluginClassLoader create(String jarPath, ClassLoader appClassLoader) {
        Path pluginJar = Paths.get(jarPath);
        if (!Files.exists(pluginJar)) {
            throw new IllegalStateException("PluginClassLoader unable to locate jar file: " + jarPath);
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
