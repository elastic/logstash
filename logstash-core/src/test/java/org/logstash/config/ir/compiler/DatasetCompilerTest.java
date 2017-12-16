package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.jruby.runtime.ThreadContext;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.FieldReference;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.nullValue;
import static org.hamcrest.MatcherAssert.assertThat;

public final class DatasetCompilerTest {

    @Test
    public void compilesEmptyMethod() {
        final Dataset func = DatasetCompiler.compile(
            Closure.wrap(SyntaxFactory.ret(DatasetCompiler.BATCH_ARG.call("to_a"))),
            Closure.EMPTY, new ClassFields(), DatasetCompiler.DatasetFlavor.ROOT, "foo"
        );
        final RubyArray batch = RubyUtil.RUBY.newArray();
        assertThat(func.compute(batch, false, false), is(batch));
    }

    @Test
    public void compilesParametrizedMethod() {
        final RubyArray batch = RubyUtil.RUBY.newArray(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event())
        );
        final VariableDefinition eventsDef = new VariableDefinition(Collection.class, "events");
        final ValueSyntaxElement events = eventsDef.access();
        final ClassFields fields = new ClassFields();
        final Dataset func = DatasetCompiler.compile(
            Closure.wrap(
                SyntaxFactory.definition(eventsDef, DatasetCompiler.BATCH_ARG.call("to_a")),
                events.call(
                    "add",
                    fields.add(
                        JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event())
                    )
                ),
                SyntaxFactory.ret(events)
            ),
            Closure.EMPTY, fields, DatasetCompiler.DatasetFlavor.ROOT, "foo"
        );
        assertThat(func.compute(batch, false, false).size(), is(2));
    }

    /**
     * Smoke test ensuring that output {@link Dataset} is compiled correctly.
     */
    @Test
    public void compilesOutputDataset() {
        assertThat(
            DatasetCompiler.outputDataset(
                DatasetCompiler.ROOT_DATASETS,
                RubyUtil.RUBY.evalScriptlet(
                    "output = Object.new\noutput.define_singleton_method(:multi_receive) do |batch|\nend\noutput"
                ),
                "foo", true
            ).compute(RubyUtil.RUBY.newArray(), false, false),
            nullValue()
        );
    }

    @Test
    public void compilesSplitDataset() {
        final FieldReference key = FieldReference.from("foo");
        final EventCondition condition = event -> event.getEvent().includes(key);
        final SplitDataset left =
            DatasetCompiler.splitDataset(DatasetCompiler.ROOT_DATASETS, condition, "foo");
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

    @Test
    public void optimizesRedundantRubyThreadContext() {
        assertThat(
            Closure.wrap(
                SyntaxFactory.definition(
                    new VariableDefinition(ThreadContext.class, "context1"),
                    ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT
                ),
                SyntaxFactory.definition(
                    new VariableDefinition(ThreadContext.class, "context2"),
                    ValueSyntaxElement.GET_RUBY_THREAD_CONTEXT
                )
            ).generateCode(),
            is(
                String.join("",
                    "org.jruby.runtime.ThreadContext context=org.logstash.RubyUtil.RUBY.getCurrentContext();",
                    "org.jruby.runtime.ThreadContext context1=context;",
                    "org.jruby.runtime.ThreadContext context2=context;"
                )
            )
        );
    }
}
