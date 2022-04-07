package org.logstash.common.dlq;

import org.logstash.DLQEntry;
import org.logstash.Event;

import java.io.IOException;
import java.util.Map;


public interface IDeadLetterQueueWriter {
    void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException;
    void writeEntry(Event event, Map<String, String> reason) throws IOException;
    // These will go away
    void close();
    boolean isOpen();
    long getCurrentQueueSize();
}
