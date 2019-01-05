package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.v0.Input;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaObject;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.JavaBasePipelineExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;

@JRubyClass(name = "JavaInputDelegator")
public class JavaInputDelegatorExt extends RubyObject {
    private static final long serialVersionUID = 1L;

    private AbstractNamespacedMetricExt metric;

    private JavaBasePipelineExt pipeline;

    private Input input;

    public JavaInputDelegatorExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    public static JavaInputDelegatorExt create(final JavaBasePipelineExt pipeline,
            final AbstractNamespacedMetricExt metric, final Input input) {
        final JavaInputDelegatorExt instance =
                new JavaInputDelegatorExt(RubyUtil.RUBY, RubyUtil.JAVA_INPUT_DELEGATOR_CLASS);

        AbstractNamespacedMetricExt scopedMetric = metric.namespace(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newSymbol(input.getId()));
        scopedMetric.gauge(RubyUtil.RUBY.getCurrentContext(), MetricKeys.NAME_KEY, RubyUtil.RUBY.newString(input.getName()));
        instance.setMetric(RubyUtil.RUBY.getCurrentContext(), scopedMetric);
        instance.input = input;
        instance.pipeline = pipeline;
        return instance;
    }

    @JRubyMethod(name = "start")
    public IRubyObject start(final ThreadContext context) {
        Thread t = new Thread(() -> input.start(pipeline.getQueueWriter(input.getId())));
        t.setName(input.getId());
        t.start();
        return JavaObject.wrap(context.getRuntime(), t);
    }

    @JRubyMethod(name = "metric=")
    public IRubyObject setMetric(final ThreadContext context, final IRubyObject metric) {
        this.metric = (AbstractNamespacedMetricExt)metric;

        return this;
    }

    @JRubyMethod(name = "metric")
    public IRubyObject getMetric(final ThreadContext context) {
        return this.metric;
    }

    @JRubyMethod(name = "config_name", meta = true)
    public IRubyObject configName(final ThreadContext context) {
        return context.getRuntime().newString(input.getName());
    }

    @JRubyMethod(name = "id")
    public IRubyObject getId(final ThreadContext context) {
        return context.getRuntime().newString(input.getId());
    }

    @JRubyMethod(name = "threadable")
    public IRubyObject isThreadable(final ThreadContext context) {
        return context.fals;
    }

    @JRubyMethod(name = "register")
    public IRubyObject register(final ThreadContext context) {
        return this;
    }

    @JRubyMethod(name = "do_close")
    public IRubyObject close(final ThreadContext context) {
        return this;
    }

    @JRubyMethod(name = "stop?")
    public IRubyObject isStopping(final ThreadContext context) {
        return context.fals;
    }

    @JRubyMethod(name = "do_stop")
    public IRubyObject doStop(final ThreadContext context) {
        try {
            input.stop();
            input.awaitStop();
        } catch (InterruptedException ex) {
            // do nothing
        }
        return this;
    }

}
