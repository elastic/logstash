package org.logstash.common;

import org.junit.Assert;
import org.junit.Test;
import org.logstash.plugins.ConfigVariableExpander;
import org.logstash.secret.SecretIdentifier;

import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.Map;

import static org.logstash.secret.store.SecretStoreFactoryTest.MemoryStore;

public class ConfigVariableExpanderTest {

    @Test
    public void testNonStringValueReturnsUnchanged() {
        long nonStringValue = 42L;
        ConfigVariableExpander cve = getFakeCve(Collections.emptyMap(), Collections.emptyMap());
        Object expandedValue = cve.expand(nonStringValue);
        Assert.assertEquals(nonStringValue, expandedValue);
    }

    @Test
    public void testExpansionWithoutVariable() throws Exception {
        String key = "foo";
        ConfigVariableExpander cve = getFakeCve(Collections.emptyMap(), Collections.emptyMap());
        String expandedValue = (String) cve.expand(key);
        Assert.assertEquals(key, expandedValue);
    }

    @Test
    public void testSimpleExpansion() throws Exception {
        String key = "foo";
        String val = "bar";
        ConfigVariableExpander cve = getFakeCve(Collections.emptyMap(), Collections.singletonMap(key, val));

        String expandedValue = (String) cve.expand("${" + key + "}");
        Assert.assertEquals(val, expandedValue);
    }

    @Test
    public void testExpansionWithDefaultValue() throws Exception {
        String key = "foo";
        String val = "bar";
        String defaultValue = "baz";
        ConfigVariableExpander cve = getFakeCve(Collections.emptyMap(), Collections.emptyMap());

        String expandedValue = (String) cve.expand("${" + key + ":" + defaultValue + "}");
        Assert.assertEquals(defaultValue, expandedValue);
    }

    @Test
    public void testExpansionWithoutValueThrows() throws Exception {
        String key = "foo";
        ConfigVariableExpander cve = getFakeCve(Collections.emptyMap(), Collections.emptyMap());

        try {
            String expandedValue = (String) cve.expand("${" + key + "}");
            Assert.fail("Exception should have been thrown");
        } catch (IllegalStateException ise) {
            Assert.assertTrue(ise.getMessage().startsWith("Cannot evaluate"));
        }
    }

    @Test
    public void testPrecedenceOfSecretStoreValue() throws Exception {
        String key = "foo";
        String ssVal = "ssbar";
        String evVal = "evbar";
        String defaultValue = "defaultbar";
        ConfigVariableExpander cve = getFakeCve(
                Collections.singletonMap(key, ssVal),
                Collections.singletonMap(key, evVal));

        String expandedValue = (String) cve.expand("${" + key + ":" + defaultValue + "}");
        Assert.assertEquals(ssVal, expandedValue);
    }

    @Test
    public void testPrecedenceOfEnvironmentVariableValue() throws Exception {
        String key = "foo";
        String evVal = "evbar";
        String defaultValue = "defaultbar";
        ConfigVariableExpander cve = getFakeCve(
                Collections.emptyMap(),
                Collections.singletonMap(key, evVal));

        String expandedValue = (String) cve.expand("${" + key + ":" + defaultValue + "}");
        Assert.assertEquals(evVal, expandedValue);
    }

    private static ConfigVariableExpander getFakeCve(
            final Map<String, Object> ssValues, final Map<String, String> envVarValues) {

        MemoryStore ms = new MemoryStore();
        for (Map.Entry<String, Object> e : ssValues.entrySet()) {
            if (e.getValue() instanceof String) {
                ms.persistSecret(new SecretIdentifier(e.getKey()),
                        ((String) e.getValue()).getBytes(StandardCharsets.UTF_8));
            }
        }
        return new ConfigVariableExpander(ms, envVarValues::get);
    }

}
