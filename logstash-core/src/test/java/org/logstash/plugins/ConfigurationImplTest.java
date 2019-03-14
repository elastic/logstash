package org.logstash.plugins;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.Codec;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.plugins.codecs.Line;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class ConfigurationImplTest {

    private String stringKey = "string", numberKey = "number", booleanKey = "boolean";
    private String stringValue = "stringValue";
    private long longValue = 42L;
    private boolean booleanValue = true;

    private Configuration getTestConfiguration() {
        Map<String, Object> configValues = new HashMap<>();
        configValues.put(stringKey, stringValue);
        configValues.put(numberKey, longValue);
        configValues.put(booleanKey, booleanValue);
        return new ConfigurationImpl(configValues);
    }

    @Test
    public void testConfiguration() {
        Configuration config = getTestConfiguration();

        PluginConfigSpec<String> stringConfig = PluginConfigSpec.stringSetting(stringKey, "", false, false);
        PluginConfigSpec<Long> numberConfig = PluginConfigSpec.numSetting(numberKey, 0L, false, false);
        PluginConfigSpec<Boolean> booleanConfig = PluginConfigSpec.booleanSetting(booleanKey, false, false, false);

        Assert.assertEquals(stringValue, config.get(stringConfig));
        Assert.assertEquals(longValue, (long) config.get(numberConfig));
        Assert.assertEquals(booleanValue, config.get(booleanConfig));
    }

    @Test
    public void testDefaultValues() {
        Configuration unsetConfig = new ConfigurationImpl(new HashMap<>());

        String defaultStringValue = "defaultStringValue";
        long defaultLongValue = 43L;
        boolean defaultBooleanValue = false;

        PluginConfigSpec<String> stringConfig = PluginConfigSpec.stringSetting(stringKey, defaultStringValue, false, false);
        PluginConfigSpec<Long> numberConfig = PluginConfigSpec.numSetting(numberKey, defaultLongValue, false, false);
        PluginConfigSpec<Boolean> booleanConfig = PluginConfigSpec.booleanSetting(booleanKey, defaultBooleanValue, false, false);

        Assert.assertEquals(defaultStringValue, unsetConfig.get(stringConfig));
        Assert.assertEquals(defaultLongValue, (long) unsetConfig.get(numberConfig));
        Assert.assertEquals(defaultBooleanValue, unsetConfig.get(booleanConfig));

        Configuration config = getTestConfiguration();
        Assert.assertNotEquals(defaultStringValue, config.get(stringConfig));
        Assert.assertNotEquals(defaultLongValue, (long) config.get(numberConfig));
        Assert.assertNotEquals(defaultBooleanValue, config.get(booleanConfig));
    }

    @Test
    public void testBrokenConfig() {
        Configuration config = getTestConfiguration();

        PluginConfigSpec<Long> brokenLongConfig = PluginConfigSpec.numSetting(stringKey, 0L, false, false);
        PluginConfigSpec<Boolean> brokenBooleanConfig = PluginConfigSpec.booleanSetting(numberKey, false, false, false);
        PluginConfigSpec<String> brokenStringConfig = PluginConfigSpec.stringSetting(booleanKey, "", false, false);

        try {
            Long l = config.get(brokenLongConfig);
            Assert.fail("Did not catch invalid config value type");
        } catch (IllegalStateException e1) {
            Assert.assertTrue(e1.getMessage().contains("incompatible with defined type"));
        } catch (Exception e2) {
            Assert.fail("Did not throw correct exception for invalid config value type");
        }

        try {
            Boolean b = config.get(brokenBooleanConfig);
            Assert.fail("Did not catch invalid config value type");
        } catch (IllegalStateException e1) {
            Assert.assertTrue(e1.getMessage().contains("incompatible with defined type"));
        } catch (Exception e2) {
            Assert.fail("Did not throw correct exception for invalid config value type");
        }

        try {
            String s = config.get(brokenStringConfig);
            Assert.fail("Did not catch invalid config value type");
        } catch (IllegalStateException e1) {
            Assert.assertTrue(e1.getMessage().contains("incompatible with defined type"));
        } catch (Exception e2) {
            Assert.fail("Did not throw correct exception for invalid config value type");
        }
    }

    @Test
    public void testDefaultCodec() {
        PluginConfigSpec<Codec> codecConfig = PluginConfigSpec.codecSetting("codec", "java-line");
        Configuration config = new ConfigurationImpl(Collections.emptyMap(), new TestPluginFactory());
        Codec codec = config.get(codecConfig);
        Assert.assertTrue(codec instanceof Line);
    }

    @Test
    public void testDowncastFromLongToDouble() {
        long defaultValue = 1L;
        PluginConfigSpec<Double> doubleConfig = PluginConfigSpec.floatSetting(numberKey, defaultValue, false, false);
        Configuration config = new ConfigurationImpl(Collections.singletonMap(numberKey, defaultValue));
        double x = config.get(doubleConfig);
        Assert.assertEquals(defaultValue, x, 0.001);
    }

}

