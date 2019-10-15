package org.logstash.config.ir.compiler;

import com.google.common.annotations.VisibleForTesting;
import java.util.Collection;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.execution.WorkerLoop;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.AbstractMetricExt;

@JRubyClass(name = "OutputDelegator")
public final class OutputDelegatorExt extends AbstractOutputDelegatorExt {

    private static final long serialVersionUID = 1L;

    private IRubyObject outputClass;

    private OutputStrategyExt.AbstractOutputStrategyExt strategy;

    @JRubyMethod(required = 5)
    public OutputDelegatorExt initialize(final ThreadContext context, final IRubyObject[] arguments) {
        return initialize(
            context, (RubyHash) arguments[4], (RubyClass) arguments[0], (AbstractMetricExt) arguments[1],
            (ExecutionContextExt) arguments[2],
            (OutputStrategyExt.OutputStrategyRegistryExt) arguments[3]
        );
    }

    public OutputDelegatorExt initialize(final ThreadContext context, final RubyHash args,
        final RubyClass outputClass, final AbstractMetricExt metric,
        final ExecutionContextExt executionContext,
        final OutputStrategyExt.OutputStrategyRegistryExt strategyRegistry) {
        this.outputClass = outputClass;

        String id = args.op_aref(context, RubyString.newString(context.runtime, "id")).asJavaString();
        RubyString configRefKey = RubyString.newString(context.runtime, "config-ref");
        String configRef = args.op_aref(context, configRefKey).asJavaString();
        initMetrics(id, metric, configRef);

        args.remove(configRefKey);
        strategy = (OutputStrategyExt.AbstractOutputStrategyExt) strategyRegistry.classFor(
            context, concurrency(context)
        ).newInstance(
            context, new IRubyObject[]{outputClass, namespacedMetric, executionContext, args},
            Block.NULL_BLOCK
        );
        return this;
    }

    public OutputDelegatorExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    @VisibleForTesting
    public OutputStrategyExt.AbstractOutputStrategyExt strategy() {
        return strategy;
    }

    @Override
    protected IRubyObject getConfigName(final ThreadContext context) {
        return outputClass.callMethod(context, "config_name");
    }

    @Override
    protected IRubyObject getConcurrency(final ThreadContext context) {
        return outputClass.callMethod(context, "concurrency");
    }

    @Override
    protected void doOutput(final Collection<JrubyEventExtLibrary.RubyEvent> batch) {
        try {
            strategy.multiReceive(WorkerLoop.THREAD_CONTEXT.get(), (IRubyObject) batch);
        } catch (final InterruptedException ex) {
            throw new IllegalStateException(ex);
        }
    }

    @Override
    protected void close(final ThreadContext context) {
        strategy.doClose(context);
    }

    @Override
    protected void doRegister(final ThreadContext context) {
        strategy.register(context);
    }

    @Override
    protected IRubyObject reloadable(final ThreadContext context) {
        return outputClass.callMethod(context, "reloadable?");
    }

}
