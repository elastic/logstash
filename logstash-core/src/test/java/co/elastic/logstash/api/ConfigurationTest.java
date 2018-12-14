package co.elastic.logstash.api;

import org.junit.Assert;
import org.junit.Test;

import java.util.HashMap;
import java.util.Map;

public class ConfigurationTest {

    private String stringKey = "string", numberKey = "number", booleanKey = "boolean";
    private String stringValue = "stringValue";
    private long longValue = 42L;
    private boolean booleanValue = true;

    private Configuration getTestConfiguration() {
        Map<String, Object> configValues = new HashMap<>();
        configValues.put(stringKey, stringValue);
        configValues.put(numberKey, longValue);
        configValues.put(booleanKey, booleanValue);
        return new Configuration(configValues);
    }

    @Test
    public void testConfiguration() {
        Configuration config = getTestConfiguration();

        PluginConfigSpec<String> stringConfig = new PluginConfigSpec<>(stringKey, String.class, "", false, false);
        PluginConfigSpec<Long> numberConfig = new PluginConfigSpec<>(numberKey, Long.class, 0L, false, false);
        PluginConfigSpec<Boolean> booleanConfig = new PluginConfigSpec<>(booleanKey, Boolean.class, false, false, false);

        Assert.assertEquals(stringValue, config.get(stringConfig));
        Assert.assertEquals(longValue, (long) config.get(numberConfig));
        Assert.assertEquals(booleanValue, config.get(booleanConfig));
    }

    @Test
    public void testDefaultValues() {
        Configuration unsetConfig = new Configuration(new HashMap<>());

        String defaultStringValue = "defaultStringValue";
        long defaultLongValue = 43L;
        boolean defaultBooleanValue = false;

        PluginConfigSpec<String> stringConfig = new PluginConfigSpec<>(stringKey, String.class, defaultStringValue, false, false);
        PluginConfigSpec<Long> numberConfig = new PluginConfigSpec<>(numberKey, Long.class, defaultLongValue, false, false);
        PluginConfigSpec<Boolean> booleanConfig = new PluginConfigSpec<>(booleanKey, Boolean.class, defaultBooleanValue, false, false);

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

        PluginConfigSpec<Long> brokenLongConfig = new PluginConfigSpec<>(stringKey, Long.class, 0L, false, false);
        PluginConfigSpec<Boolean> brokenBooleanConfig = new PluginConfigSpec<>(numberKey, Boolean.class, false, false, false);
        PluginConfigSpec<String> brokenStringConfig = new PluginConfigSpec<>(booleanKey, String.class, "", false, false);

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
}
