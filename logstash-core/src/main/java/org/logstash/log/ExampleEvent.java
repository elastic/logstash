package org.logstash.log;

import java.util.HashMap;
import java.util.Map;

public class ExampleEvent {
    private final Map<String, Object> data;

    public ExampleEvent() {
        this.data = new HashMap<>();
    }

    public void setField(String fieldName, Object value) {
        this.data.put(fieldName, value);
    }

    public Object getValue(String fieldName) {
        return this.data.get(fieldName);
    }

    public Map<String, Object> getData() {
        return this.data;
    }
}
