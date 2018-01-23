package org.logstash.ext;

import java.util.Collection;
import java.util.concurrent.atomic.AtomicBoolean;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;

@JRubyClass(name = "AckedWriteClient")
public final class JrubyAckedWriteClientExt extends RubyObject {

    private JRubyAckedQueueExt queue;

    private AtomicBoolean closed;

    @JRubyMethod(meta = true, required = 2)
    public static IRubyObject create(final ThreadContext context, IRubyObject recv,
        final IRubyObject queue, final IRubyObject closed) {
        return new JrubyAckedWriteClientExt(
            context.runtime, RubyUtil.ACKED_WRITE_CLIENT_CLASS,
            (JRubyAckedQueueExt) queue.toJava(
                JRubyAckedQueueExt.class
            ),
            (AtomicBoolean) closed.toJava(AtomicBoolean.class)
        );
    }

    public JrubyAckedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyAckedWriteClientExt(final Ruby runtime, final RubyClass metaClass,
        final JRubyAckedQueueExt queue, final AtomicBoolean closed) {
        super(runtime, metaClass);
        this.queue = queue;
        this.closed = closed;
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public IRubyObject rubyPush(final ThreadContext context, IRubyObject event) {
        ensureOpen();
        queue.ruby_write(context, event);
        return this;
    }

    @JRubyMethod(name = "push_batch", required = 1)
    public IRubyObject rubyPushBatch(final ThreadContext context, IRubyObject batch) {
        ensureOpen();
        for (final IRubyObject event : (Collection<JrubyEventExtLibrary.RubyEvent>) batch) {
            queue.ruby_write(context, event);
        }
        return this;
    }

    private void ensureOpen() {
        if (closed.get()) {
            throw new IllegalStateException("Tried to write to a closed queue.");
        }
    }
}
