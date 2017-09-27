package org.logstash.plugin;

import org.logstash.common.io.DeadLetterQueueWriter;

public interface UsesDLQ {
    void setDLQ(DeadLetterQueueWriter dlq);
}
