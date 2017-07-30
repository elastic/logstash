package org.logstash;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public final class FieldReference {

    private static final Pattern SPLIT_PATTERN = Pattern.compile("[\\[\\]]");
    private static final String[] EMPTY_STRING_ARRAY = new String[0];

    private final String[] path;
    private final String key;

    private FieldReference(final List<String> path, final String key) {
        this.path = path.toArray(EMPTY_STRING_ARRAY);
        this.key = key;
    }

    public String[] getPath() {
        return path;
    }

    public String getKey() {
        return key;
    }

    public static FieldReference parse(final CharSequence reference) {
        final String[] parts = SPLIT_PATTERN.split(reference);
        final List<String> path = new ArrayList<>(parts.length);
        for (final String part : parts) {
            if (!part.isEmpty()) {
                path.add(part);
            }
        }
        return new FieldReference(path, path.remove(path.size() - 1));
    }
}
