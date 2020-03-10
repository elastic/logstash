package org.logstash.common;

import co.elastic.logstash.api.DeadLetterQueueWriter;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.Plugin;

import java.io.IOException;

public class NullDeadLetterQueueWriter implements DeadLetterQueueWriter {
    private static final NullDeadLetterQueueWriter INSTANCE = new NullDeadLetterQueueWriter();

    private NullDeadLetterQueueWriter() {
    }

    public static NullDeadLetterQueueWriter getInstance() {
        return INSTANCE;
    }

    @Override
    public void writeEntry(Event event, Plugin plugin, String reason) throws IOException {
        // no-op
    }

    @Override
    public boolean isOpen() {
        return false;
    }

    @Override
    public long getCurrentQueueSize() {
        return 0;
    }
}
