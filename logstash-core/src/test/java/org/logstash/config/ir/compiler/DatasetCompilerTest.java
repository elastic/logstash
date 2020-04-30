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


package org.logstash.config.ir.compiler;

import java.util.Collections;
import org.jruby.RubyArray;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
import org.logstash.config.ir.PipelineTestUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;

public final class DatasetCompilerTest {

    /**
     * Smoke test ensuring that output {@link Dataset} is compiled correctly.
     */
    @Test
    public void compilesOutputDataset() {
        assertThat(
            DatasetCompiler.outputDataset(
                Collections.emptyList(),
                PipelineTestUtil.buildOutput(events -> {}),
                true
            ).instantiate().compute(RubyUtil.RUBY.newArray(), false, false),
            nullValue()
        );
    }

    @Test
    public void compilesSplitDataset() {
        final FieldReference key = FieldReference.from("foo");
        final SplitDataset left = DatasetCompiler.splitDataset(
            Collections.emptyList(), event -> event.getEvent().includes(key)
        ).instantiate();
        final Event trueEvent = new Event();
        trueEvent.setField(key, "val");
        final JrubyEventExtLibrary.RubyEvent falseEvent =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final Dataset right = left.right();
        @SuppressWarnings("rawtypes")
        final RubyArray batch = RubyUtil.RUBY.newArray(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, trueEvent), falseEvent
        );
        assertThat(left.compute(batch, false, false).size(), is(1));
        assertThat(right.compute(batch, false, false).size(), is(1));
    }
}
