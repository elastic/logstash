package org.logstash.plugin;

import org.junit.Test;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public class TranslateFilterPluginTest {
    @Test
    public void exampleConfig() {
        Map<String, Object> config = new HashMap<>();
        config.put("dictionary", Collections.emptyMap());
        config.put("field", "fancy");

        TranslateFilterPlugin.TranslateFilter filter = TranslateFilterPlugin.BUILDER.apply(config);
    }
}
