package org.logstash.ackedqueue.ext;

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

import java.io.IOException;
import java.util.concurrent.atomic.AtomicBoolean;

@JRubyClass(name = "WrappedAckedQueue")
public class JRubyWrappedAckedQueueExt extends RubyObject {

    private JRubyAckedQueueExt queue;
    private AtomicBoolean isClosed = new AtomicBoolean();

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

    public static JRubyWrappedAckedQueueExt createFileBased(
            String path, int capacity, int maxEvents, int checkpointMaxWrites,
            int checkpointMaxAcks, long maxBytes) throws IOException {
        JRubyWrappedAckedQueueExt wrappedQueue =
                new JRubyWrappedAckedQueueExt(JRubyAckedQueueExt.create(path, capacity, maxEvents,
                        checkpointMaxWrites, checkpointMaxAcks, maxBytes));
        wrappedQueue.queue.open();
        return wrappedQueue;
    }

    public JRubyWrappedAckedQueueExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JRubyWrappedAckedQueueExt(JRubyAckedQueueExt queue) {
        super(RubyUtil.RUBY, RubyUtil.WRAPPED_ACKED_QUEUE_CLASS);
        this.queue = queue;
    }

    @JRubyMethod(name = "queue")
    public IRubyObject rubyGetQueue(ThreadContext context) {
        return getQueue();
    }

    public JRubyAckedQueueExt getQueue() {
        return queue;
    }

    public boolean isClosed() {
        return isClosed.get();
    }

    @JRubyMethod(name = "closed?")
    public IRubyObject rubyIsClosed(ThreadContext context) {
        return RubyBoolean.newBoolean(context.runtime, isClosed());
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
    public void rubyPush(ThreadContext context, IRubyObject object) {
        checkIfClosed("write");
        queue.ruby_write(context, object);
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
        return JrubyAckedReadClientExt.create(this);
    }

    @JRubyMethod(name = "is_empty?")
    public IRubyObject rubyIsEmpty(ThreadContext context) {
        return queue.ruby_is_empty(context);
    }

    private void checkIfClosed(String action) {
        if (isClosed()) {
            throw new RuntimeException("Attempted to " + action + " on a closed AckedQueue");
        }
    }

}