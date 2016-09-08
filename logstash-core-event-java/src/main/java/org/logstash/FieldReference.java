package org.logstash;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

// TODO: implement thread-safe path cache singleton to avoid parsing

public class FieldReference {

    private List<String> path;
    private String key;
    private String reference;
    private static List<String> EMPTY_STRINGS = Arrays.asList("");

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
        List<String> path = new ArrayList(Arrays.asList(reference.split("[\\[\\]]")));
        path.removeAll(EMPTY_STRINGS);
        String key = path.remove(path.size() - 1);
        return new FieldReference(path, key, reference);
    }
}
