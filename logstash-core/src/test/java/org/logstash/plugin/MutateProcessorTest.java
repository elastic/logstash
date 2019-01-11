package org.logstash.plugin;

import org.junit.Test;
import org.logstash.Event;

import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.junit.Assert.assertThat;

public class MutateProcessorTest {
    private MutateProcessorBuilder builder = new MutateProcessorBuilder();

    private Map<String, Object> conversions = new HashMap<String, Object>() {{
        put("foo", "integer");
        put("bar", "float");
        put("baz", "boolean");
    }};

    @Test
    public void testBuilder() {
        builder.withConvert(conversions);
        Consumer<Event> consumer = builder.build();

        Event event = new Event();
        event.setField("foo", "1");
        event.setField("bar", "1");
        event.setField("baz", "true");

        consumer.accept(event);

        // Ok so... Event actually stores Long, not Integer.
        assertThat("foo type is integer", event.getField("foo"), instanceOf(Long.class));
        assertThat("foo is 1", event.getField("foo"), is(1L));

        assertThat("bar type is float", event.getField("bar"), instanceOf(Double.class));
        assertThat("bar is 1.0", event.getField("bar"), is(1.0));

        assertThat("baz type is boolean", event.getField("baz"), instanceOf(Boolean.class));
        assertThat("baz is true", event.getField("baz"), is(true));
    }
}
