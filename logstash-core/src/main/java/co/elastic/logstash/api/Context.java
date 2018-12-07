package co.elastic.logstash.api;

import org.logstash.common.io.DeadLetterQueueWriter;

/**
 * Holds Logstash Environment.
 */
public final class Context {

    public DeadLetterQueueWriter dlqWriter() {
        return null;
    }
}
