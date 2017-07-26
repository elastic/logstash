package org.logstash;

import java.util.concurrent.ConcurrentHashMap;

public final class PathCache {

    private static final ConcurrentHashMap<String, FieldReference> cache = new ConcurrentHashMap<>();

    private static final FieldReference timestamp = cache(Event.TIMESTAMP);

    private static final String BRACKETS_TIMESTAMP = "[" + Event.TIMESTAMP + "]";

    static {
        // inject @timestamp
        cache.put(BRACKETS_TIMESTAMP, timestamp);
    }

    public static boolean isTimestamp(String reference) {
        return cache(reference) == timestamp;
    }

    public static FieldReference cache(String reference) {
        // atomicity between the get and put is not important
        final FieldReference result = cache.get(reference);
        if (result != null) {
            return result;
        }
        return parseToCache(reference);
    }
    
    private static FieldReference parseToCache(final String reference) {
        final FieldReference result = FieldReference.parse(reference);
        cache.put(reference, result);
        return result;
    }
}
