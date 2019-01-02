package co.elastic.logstash.api;

import java.util.Collection;

import static co.elastic.logstash.api.TestingPlugin.TEST_PLUGIN_NAME;

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
