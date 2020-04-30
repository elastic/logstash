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


package org.logstash.config.ir.imperative;

import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.InvalidIRException;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.IRHelpers.assertSyntaxEquals;
import static org.logstash.config.ir.PluginDefinition.Type.*;
import static org.logstash.config.ir.IRHelpers.randMeta;

public class DSLTest {
    @Test
    public void testDSLOnePluginEquality() throws IncompleteSourceWithMetadataException {
        assertSyntaxEquals(iPlugin(randMeta(), FILTER, "foo"), iPlugin(randMeta(), FILTER, "foo"));
    }

    @Test
    public void testComposedPluginEquality() throws InvalidIRException {
        assertSyntaxEquals(composedPlugins(), composedPlugins());
    }

    @Test
    public void testDSLComplexEquality() throws InvalidIRException {
        assertSyntaxEquals(complexExpression(), complexExpression());
    }

    @Test
    public void testComposeSingle() throws InvalidIRException {
        assertSyntaxEquals(iPlugin(randMeta(), FILTER, "grok"), iComposeSequence(iPlugin(randMeta(), FILTER, "grok")));
    }

    @Test
    public void testComposeMulti() throws InvalidIRException {
        Statement composed = iComposeSequence(iPlugin(randMeta(), FILTER, "grok"), iPlugin(randMeta(), FILTER, "foo"));
        assertSyntaxEquals(iComposeSequence(iPlugin(randMeta(), FILTER, "grok"), iPlugin(randMeta(), FILTER, "foo")), composed);
}


    public BaseSourceComponent composedPlugins() throws InvalidIRException {
        return iComposeSequence(iPlugin(randMeta(), FILTER, "json"), iPlugin(randMeta(), FILTER, "stuff"));
    }

    public BaseSourceComponent complexExpression() throws InvalidIRException {
        return iComposeSequence(
                iPlugin(randMeta(), FILTER, "grok"),
                iPlugin(randMeta(), FILTER, "kv"),
                iIf(randMeta(), eAnd(eTruthy(eValue(5l)), eTruthy(eValue(null))),
                        iPlugin(randMeta(), FILTER, "grok"),
                        iComposeSequence(iPlugin(randMeta(), FILTER, "json"), iPlugin(randMeta(), FILTER, "stuff"))
                )
        );
    }


}
