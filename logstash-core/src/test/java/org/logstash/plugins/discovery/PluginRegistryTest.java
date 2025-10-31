package org.logstash.plugins.discovery;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.Output;
import org.junit.Test;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

public class PluginRegistryTest {

    private final PluginRegistry registry = PluginRegistry.getInstance();

    @Test
    public void discoversBuiltInInputPlugin() {
        Class<?> input = registry.getInputClass("java_stdin");
        assertNotNull(input);
        assertTrue(Input.class.isAssignableFrom(input));
    }

    @Test
    public void discoversBuiltInOutputPlugin() {
        Class<?> output = registry.getOutputClass("java_stdout");
        assertNotNull(output);
        assertTrue(Output.class.isAssignableFrom(output));
    }

    @Test
    public void discoversBuiltInFilterPlugin() {
        Class<?> filter = registry.getFilterClass("java_uuid");
        assertNotNull(filter);
        assertTrue(Filter.class.isAssignableFrom(filter));
    }

    @Test
    public void discoversBuiltInCodecPlugin() {
        Class<?> codec = registry.getCodecClass("java_line");
        assertNotNull(codec);
        assertTrue(Codec.class.isAssignableFrom(codec));
    }
}
