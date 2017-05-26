package org.logstash.instrument.metrics;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Created by andrewvc on 5/25/17.
 */
@JsonSerialize(using = AbstractMetricSerializer.class)
public abstract class AbstractMetric {
    // The use of Object here is to deal with the fact that the namespace can
    // also be a String or a Keyword in ruby.
    // At some point we should refactor these to be String, not Object
    private final List<Object> namespaces;
    private final Object key;
    private final String type = this.getClass().getName().toLowerCase();

    public AbstractMetric(List<Object> namespaces, Object key) {
        this.namespaces = namespaces;
        this.key = key;
    }

    public List<Object> getNamespaces() {
        return namespaces;
    }

    public Object getKey() {
        return key;
    }

    public String toString() {
        return this.getClass().getName() + " - " +
                "namespaces: " + getNamespaces().stream().
                    map(Object::toString).
                    collect(Collectors.joining("->")) +
                "key: " + getKey() +
                "value: " + getValue();
    }

    public Map<Object,Object> toHash() {
        HashMap<Object, Object> map = new HashMap<>();
        map.put(getKey(), getValue());
        return map;
    }

    public String getType() {
        return type;
    }

    public abstract Object getValue();
}
