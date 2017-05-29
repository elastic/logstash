package org.logstash;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
// TODO: implement thread-safe path cache singleton to avoid parsing

public class FieldReference {

    private static final Pattern SPLIT_PATTERN = Pattern.compile("[\\[\\]]");

    private List<String> path;
    private String key;
    private String reference;

    public FieldReference(List<String> path, String key, String reference) {
        this.path = path;
        this.key = key;
        this.reference = reference;
    }

    public List<String> getPath() {
        return path;
    }

    public String getKey() {
        return key;
    }

    public String getReference() {
        return reference;
    }

    public static FieldReference parse(String reference) {
        final String[] parts = SPLIT_PATTERN.split(reference);
        List<String> path = new ArrayList<>(parts.length);
        for (final String part : parts) {
            if (!part.isEmpty()) {
                path.add(part);
            }
        }
        String key = path.remove(path.size() - 1);
        return new FieldReference(path, key, reference);
    }
}
