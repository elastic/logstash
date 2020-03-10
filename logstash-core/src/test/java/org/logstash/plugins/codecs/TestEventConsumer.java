package org.logstash.plugins.codecs;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

public class TestEventConsumer implements Consumer<Map<String, Object>> {

    List<Map<String, Object>> events = new ArrayList<>();

    @Override
    public void accept(Map<String, Object> stringObjectMap) {
        events.add(new HashMap<>(stringObjectMap));
    }
}
