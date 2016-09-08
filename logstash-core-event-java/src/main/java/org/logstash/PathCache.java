package org.logstash;

import java.util.concurrent.ConcurrentHashMap;

public class PathCache {

    private static PathCache instance = null;
    private static ConcurrentHashMap<String, FieldReference> cache = new ConcurrentHashMap<>();

    private FieldReference timestamp;

    // TODO: dry with Event
    public static final String TIMESTAMP = "@timestamp";
    public static final String BRACKETS_TIMESTAMP = "[" + TIMESTAMP + "]";

    protected PathCache() {
        // inject @timestamp
        this.timestamp = cache(TIMESTAMP);
        cache(BRACKETS_TIMESTAMP, this.timestamp);
    }

    public static PathCache getInstance() {
        if (instance == null) {
            instance = new PathCache();
        }
        return instance;
    }

    public boolean isTimestamp(String reference) {
        return (cache(reference) == this.timestamp);
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
