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
     * Provides a {@link Logger} instance to plugins.
     * @param plugin The plugin for which the logger should be supplied.
     * @return       The supplied Logger instance.
     */
    Logger getLogger(Plugin plugin);

}
