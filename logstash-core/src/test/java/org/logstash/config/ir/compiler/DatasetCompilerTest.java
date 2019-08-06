package org.logstash.config.ir.compiler;

import org.jruby.RubyArray;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
import org.logstash.config.ir.PipelineTestUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collections;

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
                true,
                false
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
