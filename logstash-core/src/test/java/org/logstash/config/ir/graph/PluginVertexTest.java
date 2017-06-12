package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

/**
 * Created by andrewvc on 11/22/16.
 */
public class PluginVertexTest {
    @Test
    public void testConstructionIdHandlingWhenNoExplicitId() throws InvalidIRException {
        PluginDefinition pluginDefinition = testPluginDefinition();
        PluginVertex pluginVertex = new PluginVertex(testMetadata(), pluginDefinition);
        Graph graph = Graph.empty();
        graph.addVertex(pluginVertex);
        assertThat(pluginVertex.getId(), notNullValue());
    }

    @Test
    public void testConstructionIdHandlingWhenExplicitId() throws IncompleteSourceWithMetadataException {
        String customId = "mycustomid";
        Map<String, Object> pluginArguments = new HashMap<>();
        pluginArguments.put("id", customId);
        PluginDefinition pluginDefinition = new PluginDefinition(PluginDefinition.Type.FILTER, "myPlugin", pluginArguments);
        PluginVertex pluginVertex = new PluginVertex(testMetadata(), pluginDefinition);

        assertThat(pluginVertex.getId(), is(customId));
        assertThat(pluginVertex.getPluginDefinition().getArguments().get("id"), is(customId));
    }
}
