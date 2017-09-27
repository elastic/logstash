package org.logstash.plugin;

import org.logstash.Event;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;

public class SampleOutput implements Output, Witnessable, UsesDLQ {
    // Dead letter queue
    /**
     * Todo: DeadLetterQueueWriter should probably be an interface with two implementations:
     * 1) File-backed (the current DeadLetterQueueWriter)
     * 2) LoggingDeadLetterQueueWriter which will log to log4j2 but is incompatible with dead_letter_queue input
     * <p>
     * For options, I think '2' (log) should be the default. This would save plugin authors complexity
     * and they can write:
     * <p>
     * dlq.write(...)
     * <p>
     * and the user's configuration will determine how this behaves.
     */
    private DeadLetterQueueWriter dlq;


    /**
     * This method would be called by the pipeline after creating the output instance.
     * <p>
     * Roughly this:
     * <p>
     * if (output instanceof UsesDLQ) {
     * output.setDLQ(dlq)
     * }
     * <p>
     * Commentary: An alternative to `implements UsesDLQ` is to use annotations. Example:
     *
     * @param dlq
     * @Inject private DeadLetterQueueWriter dlq;
     * This would imply the plugin builder would need to ask this plugin for any '@Inject' annotations on fields.
     * If any are found, check the type, and determine if this is some injection we support.
     * I am not sure of this idea, even though it looks nice. My concern is that `implements ...` enforces
     * compile-time checks on types/etc that annotations would not (without lots of effort?).
     * For now, dependency injection I am finding to feel safer using interfaces than annotations. Discuss.
     */
    @Override /* UsesDLQ interface */
    public void setDLQ(DeadLetterQueueWriter dlq) {
        this.dlq = dlq;
    }

    // Metrics.
    /**
     * This is how plugins would declare metrics:
     * 1) Define their own internal private metric fields
     * 2) implement `HasMetrics`
     */
    private LongCounter eventCounter = new LongCounter("events");
    private LongCounter batchCounter = new LongCounter("batches");
    private List<Metric<?>> metrics = Arrays.asList(
            batchCounter, eventCounter
    );

    /**
     * The metrics system would invoke this.
     * <p>
     * The plugin would return a list of metrics and the metrics system would be expected to wrap this up
     * with serialization.
     * <p>
     * XXX: As an alternative, if we change Witness to be an interface, this could be `implements Witness`
     * with a method of `List&lt;Metric&lt;?&gt;&gt; witness()`
     *
     * @return
     */
    @Override /* HasMetrics interface, but maybe we refactor Witness to be an interface. */
    public List<Metric<?>> witness() {
        return metrics;
    }

    // All outputs would have this method.
    @Override /* output interface */
    public void process(Collection<Event> events) {
        batchCounter.increment();

        for (Event event : events) {
            eventCounter.increment();

            // do something with the event

            /**
             * DLQ support is optional for filters and outputs. It would only be enabled if the plugin
             * implements `UsesDLQ`.
             */
            if (dlq == null) {
                // no dlq enabled
            } else {
                // dlq
            }
        }
    }
}
