package co.elastic.logstash.api;

import java.io.IOException;

public interface DeadLetterQueueWriter {

    void writeEntry(Event event, Plugin plugin, String reason) throws IOException;

    boolean isOpen();

    long getCurrentQueueSize();
}
