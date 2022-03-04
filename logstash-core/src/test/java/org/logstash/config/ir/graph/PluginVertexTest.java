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


package org.logstash.config.ir.graph;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.PluginDefinition;

import java.util.HashMap;
import java.util.Map;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

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
