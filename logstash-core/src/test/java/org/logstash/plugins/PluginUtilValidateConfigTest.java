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

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Plugin;
import co.elastic.logstash.api.PluginConfigSpec;
import org.junit.Assert;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RunWith(Parameterized.class)
public class PluginUtilValidateConfigTest {

    private ValidateConfigTestCase testCase;

    public PluginUtilValidateConfigTest(ValidateConfigTestCase v) {
        this.testCase = v;
    }

    @SuppressWarnings("rawtypes")
    @Parameterized.Parameters(name = "{index}: {0}")
    public static Collection testParameters() {
        List<ValidateConfigTestCase> testParameters = new ArrayList<>();

        // optional config items, none provided
        List<PluginConfigSpec<?>> configSpec01 = Arrays.asList(
                PluginConfigSpec.stringSetting("foo1"), PluginConfigSpec.stringSetting("foo2"));
        TestingPlugin p01 = new TestingPlugin(configSpec01);
        Configuration config01 = new ConfigurationImpl(Collections.emptyMap());
        testParameters.add(
                new ValidateConfigTestCase("optional config items, none provided",
                        p01, config01, Collections.emptyList(), Collections.emptyList()));

        // optional config items, some provided
        List<PluginConfigSpec<?>> configSpec02 = Arrays.asList(
                PluginConfigSpec.stringSetting("foo1"), PluginConfigSpec.stringSetting("foo2"));
        TestingPlugin p02 = new TestingPlugin(configSpec02);
        Configuration config02 = new ConfigurationImpl(Collections.singletonMap("foo1", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("optional config items, some provided",
                        p02, config02, Collections.emptyList(), Collections.emptyList()));

        // optional config items, all provided
        List<PluginConfigSpec<?>> configSpec03 = Arrays.asList(
                PluginConfigSpec.stringSetting("foo1"), PluginConfigSpec.stringSetting("foo2"));
        TestingPlugin p03 = new TestingPlugin(configSpec03);
        Map<String, Object> configMap03 = new HashMap<>();
        configMap03.put("foo1", "bar");
        configMap03.put("foo2", "bar");
        Configuration config03 = new ConfigurationImpl(configMap03);
        testParameters.add(
                new ValidateConfigTestCase("optional config items, all provided",
                        p03, config03, Collections.emptyList(), Collections.emptyList()));

        // optional config items, too many provided
        List<PluginConfigSpec<?>> configSpec04 = Arrays.asList(
                PluginConfigSpec.stringSetting("foo1"), PluginConfigSpec.stringSetting("foo2"));
        TestingPlugin p04 = new TestingPlugin(configSpec04);
        Map<String, Object> configMap04 = new HashMap<>();
        configMap04.put("foo1", "bar");
        configMap04.put("foo2", "bar");
        configMap04.put("foo3", "bar");
        Configuration config04 = new ConfigurationImpl(configMap04);
        testParameters.add(
                new ValidateConfigTestCase("optional config items, too many provided",
                        p04, config04, Collections.singletonList("foo3"), Collections.emptyList()));

        // required config items, all provided
        List<PluginConfigSpec<?>> configSpec05 = Arrays.asList(PluginConfigSpec.requiredStringSetting("foo"));
        TestingPlugin p05 = new TestingPlugin(configSpec05);
        Configuration config05 = new ConfigurationImpl(Collections.singletonMap("foo", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("required config items, all provided",
                        p05, config05, Collections.emptyList(), Collections.emptyList()));

        // required config items, some provided
        List<PluginConfigSpec<?>> configSpec06 = Arrays.asList(
                PluginConfigSpec.requiredStringSetting("foo1"), PluginConfigSpec.requiredStringSetting("foo2"));
        TestingPlugin p06 = new TestingPlugin(configSpec06);
        Configuration config06 = new ConfigurationImpl(Collections.singletonMap("foo1", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("required config items, some provided",
                        p06, config06, Collections.emptyList(), Collections.singletonList("foo2")));

        // required config items, too many provided
        List<PluginConfigSpec<?>> configSpec07 = Arrays.asList(
                PluginConfigSpec.requiredStringSetting("foo1"), PluginConfigSpec.requiredStringSetting("foo2"));
        TestingPlugin p07 = new TestingPlugin(configSpec07);
        Map<String, Object> configMap07 = new HashMap<>();
        configMap07.put("foo1", "bar");
        configMap07.put("foo3", "bar");
        Configuration config07 = new ConfigurationImpl(configMap07);
        testParameters.add(
                new ValidateConfigTestCase("required config items, too many provided",
                        p07, config07, Collections.singletonList("foo3"), Collections.singletonList("foo2")));

        // optional+required config items, some provided
        List<PluginConfigSpec<?>> configSpec08 = Arrays.asList(
                PluginConfigSpec.requiredStringSetting("foo1"), PluginConfigSpec.requiredStringSetting("foo2"),
                PluginConfigSpec.stringSetting("foo3"), PluginConfigSpec.stringSetting("foo4"));

        TestingPlugin p08 = new TestingPlugin(configSpec08);
        Map<String, Object> configMap08 = new HashMap<>();
        configMap08.put("foo1", "bar");
        configMap08.put("foo2", "bar");
        configMap08.put("foo3", "bar");
        Configuration config08 = new ConfigurationImpl(configMap08);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some provided",
                        p08, config08, Collections.emptyList(), Collections.emptyList()));

        // optional+required config items, some missing
        List<PluginConfigSpec<?>> configSpec09 = Arrays.asList(
                PluginConfigSpec.requiredStringSetting("foo1"), PluginConfigSpec.requiredStringSetting("foo2"),
                PluginConfigSpec.stringSetting("foo3"), PluginConfigSpec.stringSetting("foo4"));

        TestingPlugin p09 = new TestingPlugin(configSpec09);
        Map<String, Object> configMap09 = new HashMap<>();
        configMap09.put("foo1", "bar");
        configMap09.put("foo3", "bar");
        Configuration config09 = new ConfigurationImpl(configMap09);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some missing",
                        p09, config09, Collections.emptyList(), Collections.singletonList("foo2")));

        // optional+required config items, some missing, some invalid
        List<PluginConfigSpec<?>> configSpec10 = Arrays.asList(
                PluginConfigSpec.requiredStringSetting("foo1"), PluginConfigSpec.requiredStringSetting("foo2"),
                PluginConfigSpec.stringSetting("foo3"), PluginConfigSpec.stringSetting("foo4"));

        TestingPlugin p10 = new TestingPlugin(configSpec10);
        Map<String, Object> configMap10 = new HashMap<>();
        configMap10.put("foo1", "bar");
        configMap10.put("foo3", "bar");
        configMap10.put("foo5", "bar");
        Configuration config10 = new ConfigurationImpl(configMap10);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some missing, some invalid",
                        p10, config10, Collections.singletonList("foo5"), Collections.singletonList("foo2")));

        return testParameters;
    }

    @Test
    public void testValidateConfig() {
        List<String> configErrors = PluginUtil.doValidateConfig(testCase.plugin, testCase.config);

        for (String expectedUnknown : testCase.expectedUnknownOptions) {
            Assert.assertTrue(
                    String.format("Expected [Unknown setting '%s' specified for plugin '%s']",
                            expectedUnknown, testCase.plugin.getName()),
                    configErrors.contains(String.format(
                            "Unknown setting '%s' specified for plugin '%s'", expectedUnknown,
                            testCase.plugin.getName())));
        }
        for (String expectedRequired : testCase.expectedRequiredOptions) {
            Assert.assertTrue(
                    String.format("Expected [Required setting '%s' not specified for plugin '%s']",
                            expectedRequired, testCase.plugin.getName()),
                    configErrors.contains(String.format(
                            "Required setting '%s' not specified for plugin '%s'", expectedRequired,
                            testCase.plugin.getName())));
        }
        for (String configError : configErrors) {
            if (configError.startsWith("Unknown")) {
                int quoteIndex = configError.indexOf("'");
                String configOption = configError.substring(
                        quoteIndex + 1, configError.indexOf("'", quoteIndex + 1));
                Assert.assertTrue(
                        "Unexpected config error: " + configError,
                        testCase.expectedUnknownOptions.contains(configOption));
            } else if (configError.startsWith("Required")) {
                int quoteIndex = configError.indexOf("'");
                String configOption = configError.substring(
                        quoteIndex + 1, configError.indexOf("'", quoteIndex + 1));
                Assert.assertTrue(
                        "Unexpected config error: " + configError,
                        testCase.expectedRequiredOptions.contains(configOption));
            } else {
                Assert.fail("Unknown type of config error: " + configError);
            }
        }

        Assert.assertEquals("Unexpected number of config errors",
                testCase.expectedRequiredOptions.size() + testCase.expectedUnknownOptions.size(),
                configErrors.size());
    }

    private static class ValidateConfigTestCase {
        String description;
        Plugin plugin;
        Configuration config;
        List<String> expectedUnknownOptions;
        List<String> expectedRequiredOptions;

        ValidateConfigTestCase(String description, Plugin plugin, Configuration config,
                List<String> expectedUnknownOptions, List<String> expectedRequiredOptions) {
            this.description = description;
            this.plugin = plugin;
            this.config = config;
            this.expectedUnknownOptions = expectedUnknownOptions;
            this.expectedRequiredOptions = expectedRequiredOptions;
        }

        @Override
        public String toString() {
            return description;
        }
    }
}
