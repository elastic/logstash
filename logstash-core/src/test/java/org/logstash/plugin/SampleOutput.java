package org.logstash.plugin;

import org.logstash.Event;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;

public class SampleOutput implements Output, Witnessable {
    /**
     * This is how plugins would declare metrics:
     * 1) Define their own internal private metric fields
     * 2) implement `HasMetrics`
     */
    private final LongCounter eventCounter = new LongCounter("events");
    private final LongCounter batchCounter = new LongCounter("batches");

    private final List<Metric<?>> metrics = Arrays.asList(
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
     * @return a list of metrics to export from this plugin
     */
    @Override /* HasMetrics interface, but maybe we refactor Witness to be an interface. */
    public List<Metric<?>> witness() {
        return metrics;
    }

    // All outputs would have this method.
    @Override /* output interface */
    public void process(Collection<Event> events, DeadLetterQueueWriter dlq) {
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
