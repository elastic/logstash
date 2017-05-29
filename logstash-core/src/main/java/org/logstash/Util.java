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

    public static void mapMerge(final Map<String, Object> target, final Map<String, Object> add) {
        LinkedHashSet<Object> buffer = null;
        for (final Map.Entry<String, Object> entry : add.entrySet()) {
            final String entryKey = entry.getKey();
            final Object entryValue = entry.getValue();
            final Object targetValue = target.get(entryKey);
            if (targetValue == null) {
                target.put(entryKey, entryValue);
            } else {
                if (targetValue instanceof Map && entryValue instanceof Map) {
                    mapMerge((Map<String, Object>) targetValue, (Map<String, Object>) entryValue);
                } else if (entryValue instanceof List) {
                    final List<Object> entryValueList = (List<Object>) entryValue;
                    if (targetValue instanceof List) {
                        if (buffer == null) {
                            buffer = new LinkedHashSet<>();
                        } else {
                            buffer.clear();
                        }
                        mergeLists((List<Object>) targetValue, (List<Object>) entryValue, buffer);
                    } else {
                        final List<Object> targetValueList =
                            new ArrayList<>(entryValueList.size() + 1);
                        targetValueList.add(targetValue);
                        for (final Object o : entryValueList) {
                            if (!targetValue.equals(o)) {
                                targetValueList.add(o);
                            }
                        }
                        target.put(entryKey, targetValueList);
                    }
                } else if (targetValue instanceof List) {
                    final List<Object> targetValueList = (List<Object>) targetValue;
                    if (!targetValueList.contains(entryValue)) {
                        targetValueList.add(entryValue);
                    }
                } else if (!targetValue.equals(entryValue)) {
                    final List<Object> targetValueList = new ArrayList<>(2);
                    targetValueList.add(targetValue);
                    targetValueList.add(entryValue);
                    target.put(entryKey, targetValueList);
                }
            }
        }
    }

    /**
     * Merges elements in the source list into the target list, adding only those in the source
     * list that are not yet contained in the target list while keeping the target list ordered
     * according to last added.
     * @param target Target List
     * @param source Source List
     * @param buffer {@link LinkedHashSet} used as sort buffer
     */
    private static void mergeLists(final List<Object> target, final List<Object> source,
        final LinkedHashSet<Object> buffer) {
        buffer.addAll(target);
        buffer.addAll(source);
        target.clear();
        target.addAll(buffer);
    }
}
