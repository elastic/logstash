package org.logstash;

import java.util.concurrent.ConcurrentHashMap;

public final class PathCache {

    private static final ConcurrentHashMap<String, FieldReference> cache = new ConcurrentHashMap<>();

    private static final FieldReference timestamp = cache(Event.TIMESTAMP);

    private static final String BRACKETS_TIMESTAMP = "[" + Event.TIMESTAMP + "]";

    static {
        // inject @timestamp
        cache(BRACKETS_TIMESTAMP, timestamp);
    }

    public static boolean isTimestamp(String reference) {
        return cache(reference) == timestamp;
    }

    public FieldReference cache(String reference) {
        // atomicity between the get and put is not important
        FieldReference result = cache.get(reference);
        if (result == null) {
            result = FieldReference.parse(reference);
            cache.put(reference, result);
        }
        return result;
    }

    public FieldReference cache(String reference, FieldReference field) {
        cache.put(reference, field);
        return field;
    }
}
