package org.logstash.execution.queue;

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

public final class LegacyMemoryQueueWriter implements QueueWriter {

    private final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public LegacyMemoryQueueWriter(final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        this.queue = queue;
    }

    @Override
    public void push(final Map<String, Object> event) {
        try {
            queue.put(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event(event)));
        } catch (final InterruptedException ex) {
            throw new IllegalStateException(ex);
        }
    }

}
