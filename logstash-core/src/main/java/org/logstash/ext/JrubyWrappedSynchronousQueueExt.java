package org.logstash.ext;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.AbstractWrappedQueueExt;

@JRubyClass(name = "WrappedSynchronousQueue")
public final class JrubyWrappedSynchronousQueueExt extends AbstractWrappedQueueExt {

    private BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyWrappedSynchronousQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    @SuppressWarnings("unchecked")
    public JrubyWrappedSynchronousQueueExt initialize(final ThreadContext context,
        IRubyObject size) {
        int typedSize = ((RubyNumeric)size).getIntValue();
        this.queue = new ArrayBlockingQueue<>(typedSize);
        return this;
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt getWriteClient(final ThreadContext context) {
        return JrubyMemoryWriteClientExt.create(queue);
    }

    @Override
    protected IRubyObject getReadClient() {
        // batch size and timeout are currently hard-coded to 125 and 50ms as values observed
        // to be reasonable tradeoffs between latency and throughput per PR #8707
        return JrubyMemoryReadClientExt.create(queue, 125, 50);
    }

    @Override
    public IRubyObject doClose(final ThreadContext context) {
        // no op
        return this;
    }

}
