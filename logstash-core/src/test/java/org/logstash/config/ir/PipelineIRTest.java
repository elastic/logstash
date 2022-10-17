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


package org.logstash.config.ir;

import org.junit.Test;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.Util;
import org.logstash.config.ir.graph.Graph;
import org.logstash.plugins.ConfigVariableExpander;
import org.logstash.config.ir.graph.QueueVertex;

import static org.hamcrest.Matchers.any;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.hasItem;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;
import static org.logstash.config.ir.IRHelpers.randMeta;

public class PipelineIRTest {
    public Graph makeInputSection() throws InvalidIRException {
        return iComposeParallel(iPlugin(randMeta(), INPUT, "generator"), iPlugin(randMeta(), INPUT, "stdin"))
                .toGraph(ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider()));
    }

    public Graph makeFilterSection() throws InvalidIRException {
        return iIf(randMeta(), eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(randMeta(), FILTER, "grok"),
                                    iPlugin(randMeta(), FILTER, "kv"))
                .toGraph(ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider()));
    }

    public Graph makeOutputSection() throws InvalidIRException {
        return iIf(randMeta(), eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(randMeta(), OUTPUT, "s3"),
                                            iPlugin(randMeta(), OUTPUT, "elasticsearch")),
                                    iPlugin(randMeta(), OUTPUT, "stdout"))
                .toGraph(ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider()));
    }

    @Test
    public void testPipelineCreation() throws InvalidIRException {
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection());
        assertEquals(2, pipelineIR.getInputPluginVertices().size());
        assertEquals(2, pipelineIR.getFilterPluginVertices().size());
        assertEquals(3, pipelineIR.getOutputPluginVertices().size());
    }

    @Test
    public void hashingWithoutOriginalSource() throws InvalidIRException {
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection());
        assertEquals(pipelineIR.uniqueHash(), pipelineIR.getGraph().uniqueHash());
    }

    @Test
    public void hashingWithOriginalSource() throws InvalidIRException {
        String source = "input { stdin {} } output { stdout {} }";
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection(), source);
        assertEquals(pipelineIR.uniqueHash(), Util.digest(source));
    }

    @Test
    public void testGetPostQueue() throws InvalidIRException {
        String source = "input { stdin {} } output { stdout {} }";
        PipelineIR pipelineIR = new PipelineIR(makeInputSection(), makeFilterSection(), makeOutputSection(), source);
        assertThat(pipelineIR.getPostQueue(), not(hasItem(any(QueueVertex.class))));
    }
}
