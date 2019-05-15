package org.logstash.common;

import co.elastic.logstash.api.DeadLetterQueueWriter;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.Plugin;

import java.io.IOException;
import java.util.Objects;

public class DLQWriterAdapter implements DeadLetterQueueWriter {

    private final org.logstash.common.io.DeadLetterQueueWriter dlqWriter;

    public DLQWriterAdapter(org.logstash.common.io.DeadLetterQueueWriter dlqWriter) {
        this.dlqWriter = Objects.requireNonNull(dlqWriter);
    }

    @Override
    public void writeEntry(Event event, Plugin plugin, String reason) throws IOException {
        dlqWriter.writeEntry((org.logstash.Event) event, plugin.getName(), plugin.getId(), reason);
    }

    @Override
    public boolean isOpen() {
        return dlqWriter != null && dlqWriter.isOpen();
    }

    @Override
    public long getCurrentQueueSize() {
        return dlqWriter != null ? dlqWriter.getCurrentQueueSize() : 0;
    }
}
