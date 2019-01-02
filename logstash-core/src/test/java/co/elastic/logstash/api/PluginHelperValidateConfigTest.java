package co.elastic.logstash.api;

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
public class PluginHelperValidateConfigTest {

    private ValidateConfigTestCase testCase;

    public PluginHelperValidateConfigTest(ValidateConfigTestCase v) {
        this.testCase = v;
    }

    @Parameterized.Parameters(name = "{index}: {0}")
    public static Collection testParameters() {
        List<ValidateConfigTestCase> testParameters = new ArrayList<>();

        // optional config items, none provided
        List<PluginConfigSpec<?>> configSpec01 = Arrays.asList(
                Configuration.stringSetting("foo1"), Configuration.stringSetting("foo2"));
        TestingPlugin p01 = new TestingPlugin(configSpec01);
        Configuration config01 = new Configuration(Collections.emptyMap());
        testParameters.add(
                new ValidateConfigTestCase("optional config items, none provided",
                        p01, config01, Collections.emptyList(), Collections.emptyList()));

        // optional config items, some provided
        List<PluginConfigSpec<?>> configSpec02 = Arrays.asList(
                Configuration.stringSetting("foo1"), Configuration.stringSetting("foo2"));
        TestingPlugin p02 = new TestingPlugin(configSpec02);
        Configuration config02 = new Configuration(Collections.singletonMap("foo1", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("optional config items, some provided",
                        p02, config02, Collections.emptyList(), Collections.emptyList()));

        // optional config items, all provided
        List<PluginConfigSpec<?>> configSpec03 = Arrays.asList(
                Configuration.stringSetting("foo1"), Configuration.stringSetting("foo2"));
        TestingPlugin p03 = new TestingPlugin(configSpec03);
        Map<String, Object> configMap03 = new HashMap<>();
        configMap03.put("foo1", "bar");
        configMap03.put("foo2", "bar");
        Configuration config03 = new Configuration(configMap03);
        testParameters.add(
                new ValidateConfigTestCase("optional config items, all provided",
                        p03, config03, Collections.emptyList(), Collections.emptyList()));

        // optional config items, too many provided
        List<PluginConfigSpec<?>> configSpec04 = Arrays.asList(
                Configuration.stringSetting("foo1"), Configuration.stringSetting("foo2"));
        TestingPlugin p04 = new TestingPlugin(configSpec04);
        Map<String, Object> configMap04 = new HashMap<>();
        configMap04.put("foo1", "bar");
        configMap04.put("foo2", "bar");
        configMap04.put("foo3", "bar");
        Configuration config04 = new Configuration(configMap04);
        testParameters.add(
                new ValidateConfigTestCase("optional config items, too many provided",
                        p04, config04, Collections.singletonList("foo3"), Collections.emptyList()));

        // required config items, all provided
        List<PluginConfigSpec<?>> configSpec05 = Arrays.asList(Configuration.requiredStringSetting("foo"));
        TestingPlugin p05 = new TestingPlugin(configSpec05);
        Configuration config05 = new Configuration(Collections.singletonMap("foo", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("required config items, all provided",
                        p05, config05, Collections.emptyList(), Collections.emptyList()));

        // required config items, some provided
        List<PluginConfigSpec<?>> configSpec06 = Arrays.asList(
                Configuration.requiredStringSetting("foo1"), Configuration.requiredStringSetting("foo2"));
        TestingPlugin p06 = new TestingPlugin(configSpec06);
        Configuration config06 = new Configuration(Collections.singletonMap("foo1", "bar"));
        testParameters.add(
                new ValidateConfigTestCase("required config items, some provided",
                        p06, config06, Collections.emptyList(), Collections.singletonList("foo2")));

        // required config items, too many provided
        List<PluginConfigSpec<?>> configSpec07 = Arrays.asList(
                Configuration.requiredStringSetting("foo1"), Configuration.requiredStringSetting("foo2"));
        TestingPlugin p07 = new TestingPlugin(configSpec07);
        Map<String, Object> configMap07 = new HashMap<>();
        configMap07.put("foo1", "bar");
        configMap07.put("foo3", "bar");
        Configuration config07 = new Configuration(configMap07);
        testParameters.add(
                new ValidateConfigTestCase("required config items, too many provided",
                        p07, config07, Collections.singletonList("foo3"), Collections.singletonList("foo2")));

        // optional+required config items, some provided
        List<PluginConfigSpec<?>> configSpec08 = Arrays.asList(
                Configuration.requiredStringSetting("foo1"), Configuration.requiredStringSetting("foo2"),
                Configuration.stringSetting("foo3"), Configuration.stringSetting("foo4"));

        TestingPlugin p08 = new TestingPlugin(configSpec08);
        Map<String, Object> configMap08 = new HashMap<>();
        configMap08.put("foo1", "bar");
        configMap08.put("foo2", "bar");
        configMap08.put("foo3", "bar");
        Configuration config08 = new Configuration(configMap08);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some provided",
                        p08, config08, Collections.emptyList(), Collections.emptyList()));

        // optional+required config items, some missing
        List<PluginConfigSpec<?>> configSpec09 = Arrays.asList(
                Configuration.requiredStringSetting("foo1"), Configuration.requiredStringSetting("foo2"),
                Configuration.stringSetting("foo3"), Configuration.stringSetting("foo4"));

        TestingPlugin p09 = new TestingPlugin(configSpec09);
        Map<String, Object> configMap09 = new HashMap<>();
        configMap09.put("foo1", "bar");
        configMap09.put("foo3", "bar");
        Configuration config09 = new Configuration(configMap09);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some missing",
                        p09, config09, Collections.emptyList(), Collections.singletonList("foo2")));

        // optional+required config items, some missing, some invalid
        List<PluginConfigSpec<?>> configSpec10 = Arrays.asList(
                Configuration.requiredStringSetting("foo1"), Configuration.requiredStringSetting("foo2"),
                Configuration.stringSetting("foo3"), Configuration.stringSetting("foo4"));

        TestingPlugin p10 = new TestingPlugin(configSpec10);
        Map<String, Object> configMap10 = new HashMap<>();
        configMap10.put("foo1", "bar");
        configMap10.put("foo3", "bar");
        configMap10.put("foo5", "bar");
        Configuration config10 = new Configuration(configMap10);
        testParameters.add(
                new ValidateConfigTestCase("optional+required config items, some missing, some invalid",
                        p10, config10, Collections.singletonList("foo5"), Collections.singletonList("foo2")));

        return testParameters;
    }

    @Test
    public void testValidateConfig() {
        List<String> configErrors = PluginHelper.doValidateConfig(testCase.plugin, testCase.config);

        for (String expectedUnknown : testCase.expectedUnknownOptions) {
            Assert.assertTrue(
                    String.format("Expected [Unknown config option '%s' specified for plugin '%s']",
                            expectedUnknown, testCase.plugin.getName()),
                    configErrors.contains(String.format(
                            "Unknown config option '%s' specified for plugin '%s'", expectedUnknown,
                            testCase.plugin.getName())));
        }
        for (String expectedRequired : testCase.expectedRequiredOptions) {
            Assert.assertTrue(
                    String.format("Expected [Required config option '%s' not specified for plugin '%s']",
                            expectedRequired, testCase.plugin.getName()),
                    configErrors.contains(String.format(
                            "Required config option '%s' not specified for plugin '%s'", expectedRequired,
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



