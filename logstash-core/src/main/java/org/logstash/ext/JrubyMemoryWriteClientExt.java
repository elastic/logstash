package org.logstash.ext;

import java.util.Collection;
import java.util.concurrent.BlockingQueue;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;

@JRubyClass(name = "MemoryWriteClient")
public final class JrubyMemoryWriteClientExt extends JRubyAbstractQueueWriteClientExt {

    private BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass,
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        super(runtime, metaClass);
        this.queue = queue;
    }

    public static JrubyMemoryWriteClientExt create(
        final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        return new JrubyMemoryWriteClientExt(RubyUtil.RUBY,
            RubyUtil.MEMORY_WRITE_CLIENT_CLASS, queue);
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt doPush(final ThreadContext context,
        final JrubyEventExtLibrary.RubyEvent event)
        throws InterruptedException {
        queue.put(event);
        return this;
    }

    @Override
    public JRubyAbstractQueueWriteClientExt doPushBatch(final ThreadContext context,
        final Collection<JrubyEventExtLibrary.RubyEvent> batch) throws InterruptedException {
        LsQueueUtils.addAll(queue, batch);
        return this;
    }
}
