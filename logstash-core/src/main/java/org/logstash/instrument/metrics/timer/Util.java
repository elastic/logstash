package org.logstash.instrument.metrics.timer;

public class Util {
    private Util() {}

    private static final long NANOS_PER_MILLI = 1_000_000L;

    static long wholeMillisFromNanos(final long excessNanos) {
        return Math.floorDiv(excessNanos, NANOS_PER_MILLI);
    }

    static int subMilliExcessNanos(final long excessNanos) {
        return Math.toIntExact(Math.floorMod(excessNanos, NANOS_PER_MILLI));
    }
}
