package org.logstash.plugins;

import org.junit.Test;
import org.logstash.plugins.PluginLookup.PluginType;

import static org.junit.Assert.*;

public class AliasRegistryTest {

    @Test
    public void testLoadAliasesFromYAML() {
        final AliasRegistry sut = new AliasRegistry();

        assertEquals("aliased_input1 should be the alias for beats input",
                "beats", sut.originalFromAlias(PluginType.INPUT, "aliased_input1"));
        assertEquals("aliased_input2 should be the alias for tcp input",
                "tcp", sut.originalFromAlias(PluginType.INPUT, "aliased_input2"));
        assertEquals("aliased_filter should be the alias for json filter",
                "json", sut.originalFromAlias(PluginType.FILTER, "aliased_filter"));
    }
}