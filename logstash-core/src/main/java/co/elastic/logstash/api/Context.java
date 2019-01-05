package co.elastic.logstash.api;

import org.logstash.common.io.DeadLetterQueueWriter;

/**
 * Holds Logstash context for plugins.
 */
public final class Context {
    private DeadLetterQueueWriter dlqWriter;

    public Context(DeadLetterQueueWriter dlqWriter) {
        this.dlqWriter = dlqWriter;
    }

    public DeadLetterQueueWriter dlqWriter() {
        return dlqWriter;
    }
}
