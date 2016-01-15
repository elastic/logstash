package com.logstash;

import org.codehaus.jackson.JsonGenerationException;
import org.codehaus.jackson.map.ObjectMapper;

import java.io.IOException;
import java.util.List;
import java.util.Map;

/**
 * Created by ph on 15-05-22.
 */
public class KeyNode implements TemplateNode {
    private String key;

    public KeyNode(String key) {
        this.key = key;
    }

    /**
     This will be more complicated with hash and array.
     leverage jackson lib to do the actual.
     */
    @Override
    public String evaluate(Event event) throws IOException {
        Object value = event.getField(this.key);

        if (value != null) {
            if (value instanceof List) {
                return join((List)value, ",");
            } else if (value instanceof Map) {
                ObjectMapper mapper = new ObjectMapper();
                return mapper.writeValueAsString((Map<String, Object>)value);
            } else {
                return event.getField(this.key).toString();
            }

        } else {
            return "%{" + this.key + "}";
        }
    }

    // TODO: (colin) this should be moved somewhere else to make it reusable
    //   this is a quick fix to compile on JDK7 a not use String.join that is
    //   only available in JDK8
    public static String join(List<?> list, String delim) {
        int len = list.size();

        if (len == 0) return "";

        StringBuilder result = new StringBuilder(list.get(0).toString());
        for (int i = 1; i < len; i++) {
            result.append(delim);
            result.append(list.get(i).toString());
        }
        return result.toString();
    }
}