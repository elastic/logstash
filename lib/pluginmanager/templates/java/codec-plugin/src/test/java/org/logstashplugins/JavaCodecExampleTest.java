package org.logstashplugins;

import co.elastic.logstash.api.Configuration;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.plugins.ConfigurationImpl;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

public class JavaCodecExampleTest {

    @Test
    public void testJavaCodec_decode() {
        String delimiter = "/";
        Map<String, Object> configValues = new HashMap<>();
        configValues.put(JavaCodecExample.DELIMITER_CONFIG.name(), delimiter);
        Configuration config = new ConfigurationImpl(configValues);
        JavaCodecExample codec = new JavaCodecExample(config, null);

        TestConsumer testConsumer = new TestConsumer();
        String[] inputs = {"foo", "bar", "baz"};
        String input = String.join(delimiter, inputs);
        codec.decode(ByteBuffer.wrap(input.getBytes()), testConsumer);

        List<Map<String, Object>> events = testConsumer.getEvents();
        Assert.assertEquals(inputs.length, events.size());
        for (int k = 0; k < inputs.length; k++) {
            Assert.assertEquals(inputs[k], events.get(k).get("message"));
        }
    }

    @Test
    public void testJavaCodec_encode() throws IOException {
        String delimiter = "/";
        Map<String, Object> configValues = new HashMap<>();
        configValues.put(JavaCodecExample.DELIMITER_CONFIG.name(), delimiter);
        Configuration config = new ConfigurationImpl(configValues);
        JavaCodecExample codec = new JavaCodecExample(config, null);
        ByteArrayOutputStream bos = new ByteArrayOutputStream();

        Event e = new Event();
        e.setField("message", "foo");
        codec.encode(e, bos);

        String resultString = bos.toString();
        Assert.assertTrue(resultString.contains("foo"));
        Assert.assertTrue(resultString.endsWith(delimiter));
    }

    @Test
    public void testClone() throws IOException {
        String delimiter = "/";
        Map<String, Object> configValues = new HashMap<>();
        configValues.put(JavaCodecExample.DELIMITER_CONFIG.name(), delimiter);
        Configuration config = new ConfigurationImpl(configValues);
        ByteArrayOutputStream bos1 = new ByteArrayOutputStream();
        ByteArrayOutputStream bos2 = new ByteArrayOutputStream();

        JavaCodecExample codec1 = new JavaCodecExample(config, null);
        Event e = new Event();
        e.setField("message", "foo");
        codec1.encode(e, bos1);

        JavaCodecExample codec2 = (JavaCodecExample) codec1.cloneCodec();
        codec2.encode(e, bos2);

        Assert.assertEquals(bos1.toString(), bos2.toString());
        Assert.assertNotEquals(codec1.getId(), codec2.getId());
    }
}

class TestConsumer implements Consumer<Map<String, Object>> {

    List<Map<String, Object>> events = new ArrayList<>();

    @Override
    public void accept(Map<String, Object> stringObjectMap) {
        events.add(stringObjectMap);
    }

    public List<Map<String, Object>> getEvents() {
        return events;
    }

}