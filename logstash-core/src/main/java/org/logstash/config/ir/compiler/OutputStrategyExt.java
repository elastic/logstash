package org.logstash.config.ir.compiler;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.stream.Collectors;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

public final class OutputStrategyExt {

    private OutputStrategyExt() {
        // Just a holder for the nested classes
    }

    @JRubyClass(name = "OutputDelegatorStrategyRegistry")
    public static final class OutputStrategyRegistryExt extends RubyObject {

        private static OutputStrategyExt.OutputStrategyRegistryExt instance;

        private RubyHash map;

        public OutputStrategyRegistryExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(meta = true)
        public static synchronized OutputStrategyExt.OutputStrategyRegistryExt instance(
            final ThreadContext context, final IRubyObject recv) {
            if (instance == null) {
                instance = new OutputStrategyExt.OutputStrategyRegistryExt(
                    context.runtime, RubyUtil.OUTPUT_STRATEGY_REGISTRY
                );
                instance.init(context);
            }
            return instance;
        }

        @JRubyMethod(name = "initialize")
        public IRubyObject init(final ThreadContext context) {
            map = RubyHash.newHash(context.runtime);
            return this;
        }

        @JRubyMethod
        public IRubyObject classes(final ThreadContext context) {
            return map.rb_values();
        }

        @JRubyMethod
        public IRubyObject types(final ThreadContext context) {
            return map.keys();
        }

        @JRubyMethod
        public IRubyObject register(final ThreadContext context, final IRubyObject type,
            final IRubyObject klass) {
            return map.op_aset(context, type, klass);
        }

        @JRubyMethod(name = "class_for")
        @SuppressWarnings("unchecked")
        public RubyClass classFor(final ThreadContext context, final IRubyObject type) {
            final IRubyObject klass = map.op_aref(context, type);
            if (!klass.isTrue()) {
                throw new IllegalArgumentException(
                    String.format(
                        "Could not find output delegator strategy of type '%s'. Value strategies: %s",
                        type.asJavaString(),
                        map.rb_values().stream().map(v -> ((IRubyObject) v).asJavaString())
                            .collect(Collectors.joining(", "))
                    )
                );
            }
            return (RubyClass) klass;
        }
    }

    @JRubyClass(name = "AbstractStrategy")
    public abstract static class AbstractOutputStrategyExt extends RubyObject {

        public AbstractOutputStrategyExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        @SuppressWarnings("unchecked")
        public final IRubyObject register(final ThreadContext context) {
            return reg(context);
        }

        @JRubyMethod(name = "do_close")
        @SuppressWarnings("unchecked")
        public final IRubyObject doClose(final ThreadContext context) {
            return close(context);
        }

        @JRubyMethod(name = "multi_receive")
        public final IRubyObject multiReceive(final ThreadContext context, final IRubyObject events)
            throws InterruptedException {
            return output(context, events);
        }

        protected abstract IRubyObject output(ThreadContext context, IRubyObject events)
            throws InterruptedException;

        protected abstract IRubyObject close(ThreadContext context);

        protected abstract IRubyObject reg(ThreadContext context);
    }

    @JRubyClass(name = "Legacy", parent = "AbstractStrategy")
    public static final class LegacyOutputStrategyExt extends OutputStrategyExt.AbstractOutputStrategyExt {

        private BlockingQueue<IRubyObject> workerQueue;

        private IRubyObject workerCount;

        private RubyArray workers;

        public LegacyOutputStrategyExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(name = "initialize", optional = 4)
        public IRubyObject init(final ThreadContext context, final IRubyObject[] args) {
            final RubyHash pluginArgs = (RubyHash) args[3];
            workerCount = pluginArgs.op_aref(context, context.runtime.newString("workers"));
            if (workerCount.isNil()) {
                workerCount = RubyFixnum.one(context.runtime);
            }
            final int count = workerCount.convertToInteger().getIntValue();
            workerQueue = new ArrayBlockingQueue<>(count);
            workers = context.runtime.newArray(count);
            for (int i = 0; i < count; ++i) {
                // Calling "new" here manually to allow mocking the ctor in RSpec Tests
                final IRubyObject output = args[0].callMethod(context, "new", pluginArgs);
                output.callMethod(context, "metric=", args[1]);
                output.callMethod(context, "execution_context=", args[2]);
                workers.append(output);
                workerQueue.add(output);
            }
            return this;
        }

        @JRubyMethod(name = "worker_count")
        public IRubyObject workerCount(final ThreadContext context) {
            return workerCount;
        }

        @JRubyMethod
        public IRubyObject workers(final ThreadContext context) {
            return workers;
        }

        @Override
        protected IRubyObject output(final ThreadContext context, final IRubyObject events) throws InterruptedException {
            final IRubyObject worker = workerQueue.take();
            try {
                return worker.callMethod(context, "multi_receive", events);
            } finally {
                workerQueue.put(worker);
            }
        }

        @Override
        @SuppressWarnings("unchecked")
        protected IRubyObject close(final ThreadContext context) {
            workers.forEach(worker -> ((IRubyObject) worker).callMethod(context, "do_close"));
            return this;
        }

        @Override
        @SuppressWarnings("unchecked")
        protected IRubyObject reg(final ThreadContext context) {
            workers.forEach(worker -> ((IRubyObject) worker).callMethod(context, "register"));
            return this;
        }
    }

    @JRubyClass(name = "SimpleAbstractStrategy", parent = "AbstractStrategy")
    public abstract static class SimpleAbstractOutputStrategyExt
        extends OutputStrategyExt.AbstractOutputStrategyExt {

        private IRubyObject output;

        protected SimpleAbstractOutputStrategyExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod(name = "initialize", optional = 4)
        public IRubyObject init(final ThreadContext context, final IRubyObject[] args) {
            // Calling "new" here manually to allow mocking the ctor in RSpec Tests
            output = args[0].callMethod(context, "new", args[3]);
            output.callMethod(context, "metric=", args[1]);
            output.callMethod(context, "execution_context=", args[2]);
            return this;
        }

        @Override
        protected final IRubyObject close(final ThreadContext context) {
            return output.callMethod(context, "do_close");
        }

        @Override
        protected final IRubyObject reg(final ThreadContext context) {
            return output.callMethod(context, "register");
        }

        protected final IRubyObject doOutput(final ThreadContext context, final IRubyObject events) {
            return output.callMethod(context, "multi_receive", events);
        }
    }

    @JRubyClass(name = "Single", parent = "SimpleAbstractStrategy")
    public static final class SingleOutputStrategyExt extends SimpleAbstractOutputStrategyExt {

        public SingleOutputStrategyExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @Override
        protected IRubyObject output(final ThreadContext context, final IRubyObject events) {
            synchronized (this) {
                return doOutput(context, events);
            }
        }
    }

    @JRubyClass(name = "Shared", parent = "SimpleAbstractStrategy")
    public static final class SharedOutputStrategyExt extends SimpleAbstractOutputStrategyExt {

        public SharedOutputStrategyExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @Override
        protected IRubyObject output(final ThreadContext context, final IRubyObject events) {
            return doOutput(context, events);
        }
    }
}
