package org.logstash.ackedqueue.ext;

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.execution.AbstractWrappedQueueExt;
import org.logstash.ext.JRubyAbstractQueueWriteClientExt;
import org.logstash.ext.JrubyAckedReadClientExt;
import org.logstash.ext.JrubyAckedWriteClientExt;
import org.logstash.ext.JrubyEventExtLibrary;

@JRubyClass(name = "WrappedAckedQueue")
public final class JRubyWrappedAckedQueueExt extends AbstractWrappedQueueExt {

    private JRubyAckedQueueExt queue;
    private final AtomicBoolean isClosed = new AtomicBoolean();

    @JRubyMethod(optional = 7)
    public JRubyWrappedAckedQueueExt initialize(ThreadContext context, IRubyObject[] args) throws IOException {
        args = Arity.scanArgs(context.runtime, args, 7, 0);
        int capacity = RubyFixnum.num2int(args[1]);
        int maxEvents = RubyFixnum.num2int(args[2]);
        int checkpointMaxWrites = RubyFixnum.num2int(args[3]);
        int checkpointMaxAcks = RubyFixnum.num2int(args[4]);
        long queueMaxBytes = RubyFixnum.num2long(args[6]);

        this.queue = JRubyAckedQueueExt.create(args[0].asJavaString(), capacity, maxEvents,
                checkpointMaxWrites, checkpointMaxAcks, queueMaxBytes);
        this.queue.open();

        return this;
    }

    public JRubyWrappedAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "queue")
    public JRubyAckedQueueExt rubyGetQueue() {
        return queue;
    }

    public void close() throws IOException {
        queue.close();
        isClosed.set(true);
    }

    @JRubyMethod(name = {"push", "<<"})
    public void rubyPush(ThreadContext context, IRubyObject event) {
        checkIfClosed("write");
        queue.rubyWrite(context, ((JrubyEventExtLibrary.RubyEvent) event).getEvent());
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject rubyReadBatch(ThreadContext context, IRubyObject size, IRubyObject wait) {
        checkIfClosed("read a batch");
        return queue.ruby_read_batch(context, size, wait);
    }

    @JRubyMethod(name = "is_empty?")
    public IRubyObject rubyIsEmpty(ThreadContext context) {
        return RubyBoolean.newBoolean(context.runtime, this.queue.isEmpty());
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt getWriteClient(final ThreadContext context) {
        return JrubyAckedWriteClientExt.create(queue, isClosed);
    }

    @Override
    protected IRubyObject getReadClient() {
        return JrubyAckedReadClientExt.create(queue);
    }

    @Override
    protected IRubyObject doClose(final ThreadContext context) {
        try {
            close();
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        return context.nil;
    }

    private void checkIfClosed(String action) {
        if (isClosed.get()) {
            throw new RuntimeException("Attempted to " + action + " on a closed AckedQueue");
        }
    }
}
