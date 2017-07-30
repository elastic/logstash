package org.logstash;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public final class PathCache {

    private static final Map<CharSequence, FieldReference> cache =
        new ConcurrentHashMap<>(10, 0.2F, 1);

    private static final FieldReference timestamp = cache(Event.TIMESTAMP);

    private static final CharSequence BRACKETS_TIMESTAMP =
        new StringBuilder().append('[').append(Event.TIMESTAMP).append(']').toString();

    static {
        // inject @timestamp
        cache.put(BRACKETS_TIMESTAMP, timestamp);
    }

    private PathCache() {
    }

    public static boolean isTimestamp(final CharSequence reference) {
        return Event.compareString(Event.TIMESTAMP, reference);
    }

    public static FieldReference cache(final CharSequence reference) {
        // atomicity between the get and put is not important
        final FieldReference result = cache.get(reference);
        if (result != null) {
            return result;
        }
        return parseToCache(reference);
    }
    
    private static FieldReference parseToCache(final CharSequence reference) {
        final FieldReference result = FieldReference.parse(reference);
        cache.put(reference, result);
        return result;
    }
}
