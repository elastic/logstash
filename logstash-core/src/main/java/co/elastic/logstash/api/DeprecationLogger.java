package co.elastic.logstash.api;

/**
 * Used to log deprecation notices.
 * */
public interface DeprecationLogger {

    /**
     * Print to deprecation log the message with placeholder replaced by param values. The placeholder
     * are {} form, like in log4j's syntax.
     *
     * @param message string message with parameter's placeholders.
     * @param params var args with all the replacement parameters.
     * */
    void deprecated(String message, Object... params);
}
