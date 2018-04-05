package org.logstash.ext;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.AckedReadBatch;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;
import org.logstash.execution.QueueBatch;
import org.logstash.execution.QueueReadClient;
import org.logstash.execution.QueueReadClientBase;

import java.io.IOException;

@JRubyClass(name = "AckedReadClient", parent = "QueueReadClientBase")
public final class JrubyAckedReadClientExt extends QueueReadClientBase implements QueueReadClient {

    private JRubyAckedQueueExt queue;

    @JRubyMethod(meta = true, required = 1)
    public static JrubyAckedReadClientExt create(final ThreadContext context,
        final IRubyObject recv, final IRubyObject queue) {
        return new JrubyAckedReadClientExt(
            context.runtime, RubyUtil.ACKED_READ_CLIENT_CLASS, queue
        );
    }

    public static JrubyAckedReadClientExt create(IRubyObject queue) {
        return new JrubyAckedReadClientExt(RubyUtil.RUBY, RubyUtil.ACKED_READ_CLIENT_CLASS, queue);
    }

    public JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyAckedReadClientExt(final Ruby runtime, final RubyClass metaClass,
        final IRubyObject queue) {
        super(runtime, metaClass);
        this.queue = (JRubyAckedQueueExt)queue;
    }

    @Override
    public void close() throws IOException {
        queue.close();
    }

    @Override
    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @Override
    public QueueBatch newBatch() {
        return AckedReadBatch.create(queue, 0, 0);
    }

    @Override
    public QueueBatch readBatch() {
        AckedReadBatch batch =
            AckedReadBatch.create(queue, batchSize, waitForMillis);
        startMetrics(batch);
        return batch;
    }

}
