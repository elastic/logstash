package org.logstash.instrument.metrics;


import java.util.EnumSet;

/**
 * A semantic means of defining the type of metric. Also serves as the list of supported metrics.
 */
public enum MetricType {

    /**
     * A counter backed by a {@link Long} type
     */
    COUNTER_LONG("counter/long"),
    /**
     * A gauge backed by a {@link String} type
     */
    GAUGE_TEXT("gauge/text"),
    /**
     * A gauge backed by a {@link Boolean} type
     */
    GAUGE_BOOLEAN("gauge/boolean"),
    /**
     * A gauge backed by a {@link Number} type
     */
    GAUGE_NUMERIC("gauge/numeric"),
     /**
     * A gauge backed by a {@link Object} type.
     */
    GAUGE_UNKNOWN("gauge/unknown"),
    /**
     * A gauge backed by a {@link org.jruby.RubyHash} type. Note - Java consumers should not use this, exist for legacy Ruby code.
     */
    GAUGE_RUBYHASH("gauge/rubyhash"),
    /**
     * A gauge backed by a {@link org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp} type. Note - Java consumers should not use this, exist for legacy Ruby code.
     */
    GAUGE_RUBYTIMESTAMP("gauge/rubytimestamp");

    private final String type;

    MetricType(final String type) {
        this.type = type;
    }

    /**
     * Finds the {@link MetricType} enumeration that matches the provided {@link String}
     *
     * @param s The input string
     * @return The {@link MetricType} that matches the input, else null.
     */
    public static MetricType fromString(String s) {
        return EnumSet.allOf(MetricType.class).stream().filter(e -> e.asString().equalsIgnoreCase(s)).findFirst().orElse(null);
    }

    /**
     * Retrieve the {@link String} representation of this MetricType.
     *
     * @return the {@link String} representation
     */
    public String asString() {
        return type;
    }

}
