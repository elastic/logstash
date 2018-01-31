package org.logstash.common;

import org.junit.Test;
import org.logstash.Event;

import java.io.InputStream;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

public class StreamingJsonTest {
    private String part1 = "{\"array-field\":[{\"num-field\":3,\"string-field\":\"message\",\"hash-field\":{\"h2-field\":{\"a-fi";
    private String part2 = "eld\":[1,2,3.1415], \"s-field\":\"A\"}}}],\"null-field\":null,\"true-field\":true,\"false-field\":false}";
    private String part3 = "{\"field\":\"A\"}";
    private String part4 = "{\"field\":\"B\"}";
    private String part5 = "[\n" +
            "  {\n" +
            "    \"field\": \"A\"\n" +
            "  },";
    private String part6 = "\n" +
            "  {\n" +
            "    \"field\": \"B\"\n" +
            "  }\n" +
            "]";

    @Test
    public void processOneObjectSplitOverTwoStrings() throws Exception {
        List<Event> events;
        StreamingJson js = new StreamingJson();
        events = js.process(part1);
        assertThat(events.size()).isEqualTo(0);
        events = js.process(part2);
        assertThat(events.size()).isEqualTo(1);
        assertThat(events.get(0).getField("[array-field][0][hash-field][h2-field][s-field]")).isEqualTo("A");
        System.out.println(events.get(0).toJson());
        js.close();
    }

    @Test
    public void processTwoObjectsSplitOverTwoStrings() throws Exception {
        processTestRunner(part3, part4);
    }

    @Test
    public void processTwoObjectsSplitOverTwoStringsInArray() throws Exception {
        processTestRunner(part5, part6);
    }

    private void processTestRunner(final String first, final String last) throws Exception {
        List<Event> events;
        StreamingJson js = new StreamingJson();
        events = js.process(first);
        assertThat(events.size()).isEqualTo(1);
        assertThat(events.get(0).getField("[field]")).isEqualTo("A");
        System.out.println(events.get(0).toJson());
        events = js.process(last);
        assertThat(events.size()).isEqualTo(1);
        assertThat(events.get(0).getField("[field]")).isEqualTo("B");
        System.out.println(events.get(0).toJson());
        js.close();
    }

    @Test
    // for profiling
    public void processChunkedFile() throws Exception {
        StreamingJson js = new StreamingJson();
        List<Event> events;
        byte[] chunk = new byte[1024 * 4];
        int chunkLen;
        int eventsCount = 0;
        try (final InputStream src = getClass().getResourceAsStream("big-json.txt")) {
            while ((chunkLen = src.read(chunk)) != -1) {
                events = js.process(chunk, 0, chunkLen);
                eventsCount += events.size();
            }
        }
        js.close();
        System.out.printf("Events processed: %d%n", eventsCount);
    }
}
