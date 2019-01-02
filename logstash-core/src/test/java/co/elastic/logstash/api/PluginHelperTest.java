package co.elastic.logstash.api;

import org.junit.Assert;
import org.junit.Test;

import java.util.Collections;

import static co.elastic.logstash.api.TestingPlugin.TEST_PLUGIN_NAME;

public class PluginHelperTest {

    @Test
    public void testPluginId() {
        TestingPlugin plugin = new TestingPlugin(Collections.emptyList());
        String pluginId = PluginHelper.pluginId(plugin);

        Assert.assertTrue(pluginId.startsWith(TEST_PLUGIN_NAME + "_"));
    }

}

