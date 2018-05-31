package org.logstash.ext;

import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;
import org.logstash.execution.MemoryReadBatch;
import org.logstash.execution.QueueBatch;
import org.logstash.execution.QueueReadClientBase;

@JRubyClass(name = "MemoryReadClient", parent = "QueueReadClientBase")
public final class JrubyMemoryReadClientExt extends QueueReadClientBase {

    private BlockingQueue queue;

    public JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass,
                                     BlockingQueue queue, int batchSize, int waitForMillis) {
        super(runtime, metaClass);
        this.queue = queue;
        this.batchSize = batchSize;
        this.waitForNanos = TimeUnit.NANOSECONDS.convert(waitForMillis, TimeUnit.MILLISECONDS);
        this.waitForMillis = waitForMillis;
    }

    public static JrubyMemoryReadClientExt create(BlockingQueue queue, int batchSize,
                                                  int waitForMillis) {
        return new JrubyMemoryReadClientExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_READ_CLIENT_CLASS, queue, batchSize, waitForMillis);
    }

    @Override
    public void close() {
        // no-op
    }

    @Override
    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @Override
    public QueueBatch newBatch() {
        return MemoryReadBatch.create();
    }

    @Override
    public QueueBatch readBatch() throws InterruptedException {
        MemoryReadBatch batch = MemoryReadBatch.create(
                LsQueueUtils.drain(queue, batchSize, waitForNanos));
        startMetrics(batch);
        return batch;
    }


}
