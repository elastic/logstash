package org.logstash;

import com.fasterxml.jackson.databind.ObjectMapper;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;


public class Util {
    private Util() {}

    public static Object getMapFixtureJackson() throws IOException {
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"string\": \"foo\", ");
        json.append("\"int\": 42, ");
        json.append("\"float\": 42.42, ");
        json.append("\"array\": [\"bar\",\"baz\"], ");
        json.append("\"hash\": {\"string\":\"quux\"} }");

        ObjectMapper mapper = new ObjectMapper();
        return mapper.readValue(json.toString(), Object.class);
    }

    public static Map<String, Object> getMapFixtureHandcrafted() {
        HashMap<String, Object> inner = new HashMap<>();
        inner.put("string", "quux");
        HashMap<String, Object> map = new HashMap<>();
        map.put("string", "foo");
        map.put("int", 42);
        map.put("float", 42.42);
        map.put("array", Arrays.asList("bar", "baz"));
        map.put("hash", inner);
        return map;
    }

    public static void mapMerge(Map<String, Object> target, Map<String, Object> add) {
        for (Map.Entry<String, Object> e : add.entrySet()) {
            if (target.containsKey(e.getKey())) {
                if (target.get(e.getKey()) instanceof Map && e.getValue() instanceof Map) {
                    mapMerge((Map<String, Object>) target.get(e.getKey()), (Map<String, Object>) e.getValue());
                } else if (e.getValue() instanceof List) {
                    if (target.get(e.getKey()) instanceof List) {
                        // needs optimizing
                        List targetList = (List) target.get(e.getKey());
                        targetList.addAll((List) e.getValue());
                        target.put(e.getKey(), new ArrayList<Object>(new LinkedHashSet<Object>(targetList)));
                    } else {
                        Object targetValue = target.get(e.getKey());
                        List targetValueList = new ArrayList();
                        targetValueList.add(targetValue);
                        for (Object o : (List) e.getValue()) {
                            if (!targetValue.equals(o)) {
                                targetValueList.add(o);
                            }
                        }
                        target.put(e.getKey(), targetValueList);
                    }
                } else if (target.get(e.getKey()) instanceof List) {
                    List t = ((List) target.get(e.getKey()));
                    if (!t.contains(e.getValue())) {
                        t.add(e.getValue());
                    }
                } else if (!target.get(e.getKey()).equals(e.getValue())) {
                    List targetValue = new ArrayList();
                    targetValue.add(target.get(e.getKey()));
                    ((List) targetValue).add(e.getValue());
                    target.put(e.getKey(), targetValue);
                }
            } else {
                target.put(e.getKey(), e.getValue());
            }
        }
    }
}
