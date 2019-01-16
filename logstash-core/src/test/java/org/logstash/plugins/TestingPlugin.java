package org.logstash.plugins;

import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.Plugin;
import co.elastic.logstash.api.PluginConfigSpec;

import java.util.Collection;

import static org.logstash.plugins.TestingPlugin.TEST_PLUGIN_NAME;

@LogstashPlugin(name = TEST_PLUGIN_NAME)
public class TestingPlugin implements Plugin {

    static final String TEST_PLUGIN_NAME = "test_plugin";
    static final String ID = "TestingPluginId";

    private final Collection<PluginConfigSpec<?>> configSchema;

    TestingPlugin(Collection<PluginConfigSpec<?>> configSchema) {
        this.configSchema = configSchema;
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return configSchema;
    }

    @Override
    public String getId() {
        return ID;
    }
}
