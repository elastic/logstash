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

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.PluginDefinition;
import org.logstash.config.ir.SourceComponent;

public class PluginVertex extends Vertex {
    private final PluginDefinition pluginDefinition;

    public PluginDefinition getPluginDefinition() {
        return pluginDefinition;
    }


    public PluginVertex(SourceWithMetadata meta, PluginDefinition pluginDefinition) {
        // We know that if the ID value exists it will be as a string
        super(meta, (String) pluginDefinition.getArguments().get("id"));
        this.pluginDefinition = pluginDefinition;
    }

    public String toString() {
        return "P[" + pluginDefinition + "|" + this.getSourceWithMetadata() + "]";
    }

    @Override
    public PluginVertex copy() {
        return new PluginVertex(this.getSourceWithMetadata(), pluginDefinition);
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        if (other == null) return false;
        if (other == this) return true;
        if (other instanceof PluginVertex) {
            PluginVertex otherV = (PluginVertex) other;
            // We don't test ID equality because we're testing
            // Semantics, and ids have nothing to do with that
            return otherV.getPluginDefinition().sourceComponentEquals(this.getPluginDefinition());
        }
        return false;
    }
}
