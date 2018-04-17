package org.logstash.execution;

import org.logstash.execution.queue.QueueWriter;

public interface QueueWriterProvider {

    QueueWriter getQueueWriter(String inputName);
}
