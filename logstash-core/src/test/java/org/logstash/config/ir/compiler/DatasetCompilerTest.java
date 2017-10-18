package org.logstash.config.ir.compiler;

import org.hamcrest.CoreMatchers;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

public final class DatasetCompilerTest {

    @Test
    public void compilesEmptyMethod() {
        final Dataset func = DatasetCompiler.compile("return batch.to_a();", "");
        final RubyArray batch = RubyUtil.RUBY.newArray();
        MatcherAssert.assertThat(
            func.compute(batch, false, false),
            CoreMatchers.is(batch)
        );
    }

    @Test
    public void compilesParametrizedMethod() {
        final JrubyEventExtLibrary.RubyEvent additional =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event());
        final RubyArray batch = RubyUtil.RUBY.newArray(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event())
        );
        final Dataset func = DatasetCompiler.compile(
            "final Collection events = batch.to_a();events.add(field0);return events;", "",
            additional
        );
        MatcherAssert.assertThat(
            func.compute(batch, false, false).size(),
            CoreMatchers.is(2)
        );
    }
}
