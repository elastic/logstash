package co.elastic.logstash.api;

/**
 * Represents a metric namespace that other namespaces can nested within.
 */
public interface Metric {
    /**
     * Creates a namespace under the current {@link Metric} and returns it.
     *
     * @param key namespace to traverse into
     * @return the {@code key} namespace under the current Metric
     */
    NamespacedMetric namespace(String... key);
}
