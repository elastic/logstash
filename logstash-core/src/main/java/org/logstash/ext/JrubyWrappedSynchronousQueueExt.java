package org.logstash.ext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyNumeric;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;

@JRubyClass(name = "WrappedSynchronousQueue")
public final class JrubyWrappedSynchronousQueueExt extends RubyObject {

    private BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyWrappedSynchronousQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "initialize")
    @SuppressWarnings("unchecked")
    public void rubyInitialize(final ThreadContext context, IRubyObject size) {
        int typedSize = ((RubyNumeric)size).getIntValue();
        this.queue = new ArrayBlockingQueue<>(typedSize);
    }

    @JRubyMethod(name = "write_client")
    public IRubyObject getWriteClient(final ThreadContext context) {
        return JrubyMemoryWriteClientExt.create(queue);
    }

    @JRubyMethod(name = "read_client")
    public IRubyObject getReadClient(final ThreadContext context) {
        // batch size and timeout are currently hard-coded to 125 and 50ms as values observed
        // to be reasonable tradeoffs between latency and throughput per PR #8707
        return JrubyMemoryReadClientExt.create(queue, 125, 50);
    }

    @JRubyMethod(name = "close")
    public IRubyObject rubyClose(final ThreadContext context) {
        // no op
        return this;
    }

}
