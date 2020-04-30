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

import org.junit.Assert;
import org.junit.Ignore;
import org.junit.Test;
import org.logstash.plugins.codecs.Line;
import org.logstash.plugins.filters.Uuid;
import org.logstash.plugins.inputs.Generator;
import org.logstash.plugins.inputs.Stdin;
import org.logstash.plugins.outputs.Stdout;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Enumeration;
import java.util.jar.JarEntry;
import java.util.jar.JarFile;

import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;

public class PluginValidatorTest {

    @Test
    public void testValidInputPlugin() {
        Assert.assertTrue(PluginValidator.validatePlugin(PluginLookup.PluginType.INPUT, Stdin.class));
        Assert.assertTrue(PluginValidator.validatePlugin(PluginLookup.PluginType.INPUT, Generator.class));
    }

    @Test
    public void testValidFilterPlugin() {
        Assert.assertTrue(PluginValidator.validatePlugin(PluginLookup.PluginType.FILTER, Uuid.class));
    }

    @Test
    public void testValidCodecPlugin() {
        Assert.assertTrue(PluginValidator.validatePlugin(PluginLookup.PluginType.CODEC, Line.class));
    }

    @Test
    public void testValidOutputPlugin() {
        Assert.assertTrue(PluginValidator.validatePlugin(PluginLookup.PluginType.OUTPUT, Stdout.class));
    }

    @Ignore("Test failing on windows for many weeks. See https://github.com/elastic/logstash/issues/10926")
    @Test
    public void testInvalidInputPlugin() throws IOException {
        Path tempJar = null;
        try {
            tempJar = Files.createTempFile("pluginValidationTest", "inputPlugin.jar");
            final InputStream resourceJar =
                    getClass().getResourceAsStream("logstash-input-java_input_example-0.0.1.jar");
            Files.copy(resourceJar, tempJar, REPLACE_EXISTING);

            URL[] jarUrl = {tempJar.toUri().toURL()};
            URLClassLoader cl = URLClassLoader.newInstance(jarUrl);
            Class<?> oldInputClass = cl.loadClass("org.logstash.javaapi.JavaInputExample");

            Assert.assertNotNull(oldInputClass);
            Assert.assertFalse(PluginValidator.validatePlugin(PluginLookup.PluginType.INPUT, oldInputClass));
        } catch (Exception ex) {
            Assert.fail("Failed with exception: " + ex);
        } finally {
            if (tempJar != null) {
                Files.deleteIfExists(tempJar);
            }
        }
    }
}
