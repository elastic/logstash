package org.logstash.common;

import org.junit.Test;
import org.logstash.Event;

import java.io.InputStream;
import java.net.URL;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

public class StreamingJsonTest {
    private String part1 = "{\"array-field\":[{\"num-field\":3,\"string-field\":\"message\",\"hash-field\":{\"h2-field\":{\"a-fi";
    private String part2 = "eld\":[1,2,3.1415], \"s-field\":\"A\"}}}],\"null-field\":null,\"true-field\":true,\"false-field\":false}";
    private String part3 = "{\"0field\":\"A\"}";
    private String part4 = "{\"1field\":\"B\"}";
    private String part5 = "[\n" +
            "  {\n" +
            "    \"0field\": \"A\"\n" +
            "  },";
    private String part6 = "\n" +
            "  {\n" +
            "    \"1field\": \"B\"\n" +
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
        assertThat(events.get(0).getField("[0field]")).isEqualTo("A");
        events = js.process(last);
        assertThat(events.size()).isEqualTo(1);
        assertThat(events.get(0).getField("[1field]")).isEqualTo("B");
        js.close();
    }

    @Test
    // for profiling
    public void processChunkedFiles() throws Exception {
        chunkedFileRunner("big-json.txt", 5926);
        chunkedFileRunner("small-json.txt", 299);
        chunkedFileRunner("micro-json.txt", 5);
    }
    private void chunkedFileRunner(final String resourceName, final int expectedCount) throws Exception {
        StreamingJson js = new StreamingJson();
        List<Event> events;
        byte[] chunk = new byte[1024 * 4];
        int chunkLen;
        int eventsCount = 0;
        URL url = this.getClass().getResource(resourceName);
        try (final InputStream src = url.openStream()) {
            assert src != null;
            while ((chunkLen = src.read(chunk)) != -1) {
                events = js.process(chunk, 0, chunkLen);
                eventsCount += events.size();
            }
        }
        js.close();
        assertThat(eventsCount).isEqualTo(expectedCount);
    }
}
