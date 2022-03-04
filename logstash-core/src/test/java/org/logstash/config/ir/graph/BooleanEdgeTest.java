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

import org.junit.experimental.theories.DataPoint;
import org.junit.experimental.theories.Theories;
import org.junit.experimental.theories.Theory;
import org.junit.runner.RunWith;
import org.logstash.config.ir.InvalidIRException;

import static org.hamcrest.CoreMatchers.*;
import static org.junit.Assert.assertThat;
import static org.logstash.config.ir.IRHelpers.*;

@RunWith(Theories.class)
public class BooleanEdgeTest {
    @DataPoint
    public static Boolean TRUE = true;
    @DataPoint
    public static Boolean FALSE = false;

    @Theory
    public void testBasicBooleanEdgeProperties(Boolean edgeType) throws InvalidIRException {
        BooleanEdge be = new BooleanEdge(edgeType, createTestVertex(), createTestVertex());
        assertThat(be.getEdgeType(), is(edgeType));
    }

    @Theory
    public void testFactoryCreation(Boolean edgeType) throws InvalidIRException {
        BooleanEdge.BooleanEdgeFactory factory = new BooleanEdge.BooleanEdgeFactory(edgeType);
        BooleanEdge be = factory.make(createTestVertex(), createTestVertex());
        assertThat(be.getEdgeType(), is(edgeType));
    }
}
