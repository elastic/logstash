package org.logstash;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public final class PathCache {

    private static final Map<CharSequence, FieldReference> CACHE =
        new ConcurrentHashMap<>(64, 0.2F, 1);

    private PathCache() {
    }

    public static FieldReference cache(final CharSequence reference) {
        // atomicity between the get and put is not important
        final FieldReference result = CACHE.get(reference);
        if (result != null) {
            return result;
        }
        return parseToCache(reference);
    }

    private static FieldReference parseToCache(final CharSequence reference) {
        final FieldReference result = FieldReference.parse(reference);
        CACHE.put(reference, result);
        return result;
    }
}
