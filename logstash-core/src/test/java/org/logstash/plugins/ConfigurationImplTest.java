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
import co.elastic.logstash.api.Password;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.Codec;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.plugins.codecs.Line;

import java.net.URI;
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

    @Test
    public void testUriValue() {
        String defaultUri = "https://user:password@www.site.com:99";
        String uri = "https://user:password@www.site2.com:99";
        PluginConfigSpec<URI> uriConfig = PluginConfigSpec.uriSetting("test", defaultUri);
        Configuration config = new ConfigurationImpl(Collections.singletonMap("test", uri));
        URI u = config.get(uriConfig);
        Assert.assertEquals(uri, u.toString());
    }

    @Test
    public void testUriDefaultValue() {
        String defaultUri = "https://user:password@www.site.com:99";
        PluginConfigSpec<URI> uriConfig = PluginConfigSpec.uriSetting("test", defaultUri);
        Configuration config = new ConfigurationImpl(Collections.emptyMap());
        URI u = config.get(uriConfig);
        Assert.assertEquals(defaultUri, u.toString());
    }

    @Test
    public void testBadUriThrows() {
        String uri = "http://www.si%%te.com";
        PluginConfigSpec<URI> uriConfig = PluginConfigSpec.uriSetting("test", uri);
        Configuration config = new ConfigurationImpl(Collections.singletonMap("test", uri));
        try {
            config.get(uriConfig);
            Assert.fail("Did not catch invalid URI");
        } catch (IllegalStateException e1) {
            Assert.assertTrue(e1.getMessage().contains("Invalid URI specified for"));
        } catch (Exception e2) {
            Assert.fail("Did not throw correct exception for invalid URI");
        }
    }

    @Test
    public void testBadDefaultUriThrows() {
        String uri = "http://www.si%%te.com";
        PluginConfigSpec<URI> uriConfig = PluginConfigSpec.uriSetting("test", uri);
        Configuration config = new ConfigurationImpl(Collections.emptyMap());
        try {
            config.get(uriConfig);
            Assert.fail("Did not catch invalid URI");
        } catch (IllegalStateException e1) {
            Assert.assertTrue(e1.getMessage().contains("Invalid default URI specified for"));
        } catch (Exception e2) {
            Assert.fail("Did not throw correct exception for invalid URI");
        }
    }

    @Test
    public void testPassword() {
        String myPassword = "mysecret";
        PluginConfigSpec<Password> passwordConfig = PluginConfigSpec.passwordSetting("passwordTest");
        Configuration config = new ConfigurationImpl(Collections.singletonMap("passwordTest", myPassword));
        Password p = config.get(passwordConfig);
        Assert.assertEquals(Password.class, p.getClass());
        Assert.assertEquals(myPassword, p.getPassword());
        Assert.assertEquals("<password>", p.toString());
    }

    @Test
    public void testPasswordDefaultValue() {
        // default values for passwords are a bad idea, but they should still work
        String myPassword = "mysecret";
        PluginConfigSpec<Password> passwordConfig = PluginConfigSpec.passwordSetting("passwordTest", myPassword, false, false);
        Configuration config = new ConfigurationImpl(Collections.emptyMap());
        Password p = config.get(passwordConfig);
        Assert.assertEquals(Password.class, p.getClass());
        Assert.assertEquals(myPassword, p.getPassword());
        Assert.assertEquals("<password>", p.toString());
    }

    @Test
    public void testBooleanValues() {
        PluginConfigSpec<Boolean> booleanConfig = PluginConfigSpec.booleanSetting(booleanKey, false, false, false);
        Configuration config = new ConfigurationImpl(Collections.singletonMap(booleanKey, "tRuE"));
        boolean value = config.get(booleanConfig);
        Assert.assertTrue(value);

        config = new ConfigurationImpl(Collections.singletonMap(booleanKey, "false"));
        value = config.get(booleanConfig);
        Assert.assertFalse(value);

        booleanConfig = PluginConfigSpec.booleanSetting(booleanKey, false, false, false);
        config = new ConfigurationImpl(Collections.emptyMap());
        value = config.get(booleanConfig);
        Assert.assertFalse(value);

        booleanConfig = PluginConfigSpec.booleanSetting(booleanKey, true, false, false);
        config = new ConfigurationImpl(Collections.emptyMap());
        value = config.get(booleanConfig);
        Assert.assertTrue(value);
    }

}
