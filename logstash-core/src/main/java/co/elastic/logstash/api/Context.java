package co.elastic.logstash.api;

import org.apache.logging.log4j.Logger;
import org.logstash.common.io.DeadLetterQueueWriter;

/**
 * Provides Logstash context to plugins.
 */
public interface Context {

    /**
     * Provides a dead letter queue (DLQ) writer, if configured, to output plugins. If no DLQ writer
     * is configured or the plugin is not an output, {@code null} will be returned.
     * @return {@link DeadLetterQueueWriter} instance if available or {@code null} otherwise.
     */
    DeadLetterQueueWriter getDlqWriter();

    /**
     * Provides a metric namespace scoped to the given {@code plugin} that metrics can be written to and
     * can be nested deeper with further namespaces.
     * @param plugin The plugin the metric should be scoped to
     * @return       A metric scoped to the current plugin
     */
    NamespacedMetric getMetric(Plugin plugin);

    /**
     * Provides a {@link Logger} instance to plugins.
     * @param plugin The plugin for which the logger should be supplied.
     * @return       The supplied Logger instance.
     */
    Logger getLogger(Plugin plugin);

    /**
     * Provides an {@link EventFactory} to constructs instance of {@link Event}.
     * @return The event factory.
     */
    EventFactory getEventFactory();

}
