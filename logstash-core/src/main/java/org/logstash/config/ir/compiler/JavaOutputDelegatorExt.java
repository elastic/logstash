package org.logstash.config.ir.compiler;

import java.util.Collection;
import java.util.List;
import java.util.function.Consumer;
import java.util.stream.Collectors;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import co.elastic.logstash.api.Output;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractMetricExt;

@JRubyClass(name = "JavaOutputDelegator")
public final class JavaOutputDelegatorExt extends AbstractOutputDelegatorExt {

    private static final RubySymbol CONCURRENCY = RubyUtil.RUBY.newSymbol("java");

    private RubyString configName;

    private Consumer<Collection<JrubyEventExtLibrary.RubyEvent>> outputFunction;

    private Runnable closeAction;

    private Runnable registerAction;

    private Output output;

    public JavaOutputDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JavaOutputDelegatorExt create(final String configName, final String id,
        final AbstractMetricExt metric,
        final Consumer<Collection<JrubyEventExtLibrary.RubyEvent>> outputFunction,
        final Runnable closeAction, final Runnable registerAction) {
        final JavaOutputDelegatorExt instance =
            new JavaOutputDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_OUTPUT_DELEGATOR_CLASS);
        instance.configName = RubyUtil.RUBY.newString(configName);
        instance.initMetrics(id, metric);
        instance.outputFunction = outputFunction;
        instance.closeAction = closeAction;
        instance.registerAction = registerAction;
        return instance;
    }

    public static JavaOutputDelegatorExt create(final String configName, final String id,
                                                final AbstractMetricExt metric,
                                                final Output output) {
        final JavaOutputDelegatorExt instance =
                new JavaOutputDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_OUTPUT_DELEGATOR_CLASS);
        instance.configName = RubyUtil.RUBY.newString(configName);
        instance.initMetrics(id, metric);
        instance.output = output;
        instance.outputFunction = instance::outputRubyEvents;
        instance.closeAction = instance::outputClose;
        instance.registerAction = instance::outputRegister;
        return instance;
    }

    void outputRubyEvents(Collection<JrubyEventExtLibrary.RubyEvent> e) {
        List<Event> events = e.stream().map(JrubyEventExtLibrary.RubyEvent::getEvent).collect(Collectors.toList());
        output.output(events);
    }

    void outputClose() {
        output.stop();
    }

    void outputRegister() {

    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return configName;
    }

    @Override
    protected IRubyObject getConcurrency(final ThreadContext context) {
        return CONCURRENCY;
    }

    @Override
    protected void doOutput(final Collection<JrubyEventExtLibrary.RubyEvent> batch) {
        outputFunction.accept(batch);
    }

    @Override
    protected void close(final ThreadContext context) {
        closeAction.run();
    }

    @Override
    protected void doRegister(final ThreadContext context) {
        registerAction.run();
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return context.tru;
    }
}
