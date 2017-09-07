package org.logstash.plugin;

public interface Output {
    /**
     * Process a batch with the intent of sending the event externally.
     * <p>
     * If an event in the Batch is undeliverable, a plugin may indicate the delivery failure
     * by calling Batch.fail(event, ...)
     *
     * @param batch The batch to process. A batch contains events.
     */
    void process(Batch batch);
}
