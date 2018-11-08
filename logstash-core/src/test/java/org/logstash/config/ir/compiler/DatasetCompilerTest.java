package org.logstash.config.ir.compiler;

import java.util.Collections;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
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
                new OutputDelegatorExt(RubyUtil.RUBY, RubyUtil.OUTPUT_DELEGATOR_CLASS)
                    .initForTesting(
                        new OutputStrategyExt.SimpleAbstractOutputStrategyExt(
                            RubyUtil.RUBY, RubyUtil.RUBY.getObject()
                        ) {
                            @Override
                            protected IRubyObject output(final ThreadContext context, final IRubyObject events) {
                                return this;
                            }
                        }),
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
        final RubyArray batch = RubyUtil.RUBY.newArray(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, trueEvent), falseEvent
        );
        assertThat(left.compute(batch, false, false).size(), is(1));
        assertThat(right.compute(batch, false, false).size(), is(1));
    }
}
