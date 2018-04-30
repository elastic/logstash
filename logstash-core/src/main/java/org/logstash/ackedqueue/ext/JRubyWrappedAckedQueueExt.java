package org.logstash.ackedqueue.ext;

import java.io.IOException;
import java.util.Collections;
import java.util.concurrent.atomic.AtomicBoolean;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.Arity;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyAckedReadClientExt;
import org.logstash.ext.JrubyAckedWriteClientExt;
import org.logstash.ext.JrubyEventExtLibrary;

@JRubyClass(name = "WrappedAckedQueue")
public final class JRubyWrappedAckedQueueExt extends RubyObject {

    private JRubyAckedQueueExt queue;
    private final AtomicBoolean isClosed = new AtomicBoolean();

    @JRubyMethod(name = "initialize", optional = 7)
    public IRubyObject ruby_initialize(ThreadContext context, IRubyObject[] args) throws IOException {
        args = Arity.scanArgs(context.runtime, args, 7, 0);
        int capacity = RubyFixnum.num2int(args[1]);
        int maxEvents = RubyFixnum.num2int(args[2]);
        int checkpointMaxWrites = RubyFixnum.num2int(args[3]);
        int checkpointMaxAcks = RubyFixnum.num2int(args[4]);
        long queueMaxBytes = RubyFixnum.num2long(args[6]);

        this.queue = JRubyAckedQueueExt.create(args[0].asJavaString(), capacity, maxEvents,
                checkpointMaxWrites, checkpointMaxAcks, queueMaxBytes);
        this.queue.open();

        return context.nil;
    }

    public JRubyWrappedAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "queue")
    public IRubyObject rubyGetQueue(ThreadContext context) {
        return queue;
    }

    public void close() throws IOException {
        queue.close();
        isClosed.set(true);
    }

    @JRubyMethod(name = "close")
    public IRubyObject rubyClose(ThreadContext context) {
        try {
            close();
        } catch (IOException e) {
            throw RubyUtil.newRubyIOError(context.runtime, e);
        }
        return context.nil;
    }

    @JRubyMethod(name = {"push", "<<"})
    public void rubyPush(ThreadContext context, IRubyObject event) {
        checkIfClosed("write");
        queue.rubyWrite(context, Collections.singletonList(((JrubyEventExtLibrary.RubyEvent) event).getEvent()),-1);
    }

    @JRubyMethod(name = "read_batch")
    public IRubyObject rubyReadBatch(ThreadContext context, IRubyObject size, IRubyObject wait) {
        checkIfClosed("read a batch");
        return queue.ruby_read_batch(context, size, wait);
    }


    @JRubyMethod(name = "write_client")
    public IRubyObject rubyWriteClient(final ThreadContext context) {
        return JrubyAckedWriteClientExt.create(queue, isClosed);
    }

    @JRubyMethod(name = "read_client")
    public IRubyObject rubyReadClient(final ThreadContext context) {
        return JrubyAckedReadClientExt.create(queue);
    }

    @JRubyMethod(name = "is_empty?")
    public IRubyObject rubyIsEmpty(ThreadContext context) {
        return RubyBoolean.newBoolean(context.runtime, this.queue.isEmpty());
    }

    private void checkIfClosed(String action) {
        if (isClosed.get()) {
            throw new RuntimeException("Attempted to " + action + " on a closed AckedQueue");
        }
    }
}
