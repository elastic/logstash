package org.logstash;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

/**
 * Utility Methods used in RSpec Tests.
 */
public final class RspecTestUtils {

    public static Object getMapFixtureJackson() throws IOException {
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"string\": \"foo\", ");
        json.append("\"int\": 42, ");
        json.append("\"float\": 42.42, ");
        json.append("\"array\": [\"bar\",\"baz\"], ");
        json.append("\"hash\": {\"string\":\"quux\"} }");
        return ObjectMappers.JSON_MAPPER.readValue(json.toString(), Object.class);
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
}
