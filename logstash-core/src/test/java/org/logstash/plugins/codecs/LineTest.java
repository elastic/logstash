package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Plugin;
import org.apache.logging.log4j.Logger;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.plugins.ConfigurationImpl;

import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public class LineTest {

    @Test
    public void testSimpleDecode() {
        String input = "abc";
        testDecode(null, null, input, 0, 1, new String[]{input});
    }

    @Test
    public void testDecodeDefaultDelimiter() {
        String[] inputStrings = {"foo", "bar", "baz"};
        String input = String.join(Line.DEFAULT_DELIMITER, inputStrings);

        testDecode(null, null, input, inputStrings.length - 1, 1, inputStrings);
    }

    @Test
    public void testDecodeCustomDelimiter() {
        String delimiter = "z";
        String[] inputStrings = {"foo", "bar", "bat"};
        String input = String.join(delimiter, inputStrings);

        testDecode(delimiter, null, input, inputStrings.length - 1, 1, inputStrings);
    }

    @Test
    public void testDecodeWithTrailingDelimiter() {
        String delimiter = "\n";
        String[] inputs = {"foo", "bar", "baz"};
        String input = String.join(delimiter, inputs) + delimiter;

        testDecode(null, null, input, inputs.length, 0, inputs);
    }

    @Test
    public void testSuccessiveDecodesWithTrailingDelimiter() {
        // setup inputs
        String delimiter = "\n";
        String[] inputs = {"foo", "bar", "baz"};
        String input = String.join(delimiter, inputs) + delimiter;
        byte[] inputBytes = input.getBytes();
        TestEventConsumer eventConsumer = new TestEventConsumer();
        TestEventConsumer flushedEvents = new TestEventConsumer();
        Line line = getLineCodec(null, null);

        // first call to decode
        ByteBuffer buffer = ByteBuffer.allocate(inputBytes.length * 3);
        buffer.put(inputBytes);
        buffer.flip();
        line.decode(buffer, eventConsumer);
        assertEquals(inputs.length, eventConsumer.events.size());
        compareMessages(inputs, eventConsumer.events, flushedEvents.events);

        // second call to encode
        eventConsumer.events.clear();
        buffer.compact();
        buffer.put(inputBytes);
        buffer.flip();
        line.decode(buffer, eventConsumer);
        assertEquals(inputs.length, eventConsumer.events.size());
        compareMessages(inputs, eventConsumer.events, flushedEvents.events);

        buffer.compact();
        buffer.flip();
        line.flush(buffer, flushedEvents);
        assertEquals(0, flushedEvents.events.size());
    }

    @Test
    public void testDecodeOnDelimiterOnly() {
        String delimiter = "z";
        String input = "z";

        testDecode(delimiter, null, input, 0, 0, new String[]{""});
    }

    @Test
    public void testDecodeWithMulticharDelimiter() {
        String delimiter = "xyz";
        String[] inputs = {"a", "b", "c"};
        String input = String.join(delimiter, inputs);

        testDecode(delimiter, null, input, inputs.length - 1, 1, inputs);
    }

    @Test
    public void testDecodeWithMulticharTrailingDelimiter() {
        String delimiter = "xyz";
        String[] inputs = {"foo", "bar", "baz"};
        String input = String.join(delimiter, inputs) + delimiter;

        testDecode(delimiter, null, input, inputs.length, 0, inputs);
    }

    @Test
    public void testDecodeWithUtf8() {
        String input = "München 安装中文输入法";
        testDecode(null, null, input + Line.DEFAULT_DELIMITER, 1, 0, new String[]{input});
    }

    @Test
    public void testDecodeAcrossMultibyteCharBoundary() {
        final int BUFFER_SIZE = 12;
        int lastPos = 0;
        TestEventConsumer eventConsumer = new TestEventConsumer();
        String input = "安安安\n安安安\n安安安";
        byte[] bytes = input.getBytes();
        assertTrue(bytes.length > input.length());
        ByteBuffer b1 = ByteBuffer.allocate(BUFFER_SIZE);
        b1.put(bytes, lastPos, 12);
        b1.flip();

        Line line = getLineCodec(null, null);
        line.decode(b1, eventConsumer);
        b1.compact();

        int remaining = b1.remaining();
        lastPos += BUFFER_SIZE;
        b1.put(bytes, lastPos, remaining);
        b1.flip();
        line.decode(b1, eventConsumer);
        b1.compact();

        remaining = b1.remaining();
        lastPos += remaining;
        b1.put(bytes, lastPos, bytes.length - lastPos);
        b1.flip();
        line.decode(b1, eventConsumer);
        b1.compact();
        b1.flip();
        line.flush(b1, eventConsumer);
    }

    @Test
    public void testFlush() {
        String[] inputs = {"The", "quick", "brown", "fox", "jumps"};
        String input = String.join(Line.DEFAULT_DELIMITER, inputs);
        testDecode(null, null, input, inputs.length - 1, 1, inputs);
    }

    private void testDecode(String delimiter, String charset, String inputString, Integer expectedPreflushEvents, Integer expectedFlushEvents, String[] expectedMessages) {
        Line line = getLineCodec(delimiter, charset);

        byte[] inputBytes = inputString.getBytes();
        TestEventConsumer eventConsumer = new TestEventConsumer();
        ByteBuffer inputBuffer = ByteBuffer.wrap(inputBytes, 0, inputBytes.length);
        line.decode(inputBuffer, eventConsumer);
        if (expectedPreflushEvents != null) {
            assertEquals(expectedPreflushEvents.intValue(), eventConsumer.events.size());
        }

        inputBuffer.compact();
        inputBuffer.flip();

        TestEventConsumer flushConsumer = new TestEventConsumer();
        line.flush(inputBuffer, flushConsumer);
        if (expectedFlushEvents != null) {
            assertEquals(expectedFlushEvents.intValue(), flushConsumer.events.size());
        }

        compareMessages(expectedMessages, eventConsumer.events, flushConsumer.events);
    }

    private static void compareMessages(String[] expectedMessages, List<Map<String, Object>> events, List<Map<String, Object>> flushedEvents) {
        if (expectedMessages != null) {
            for (int k = 0; k < events.size(); k++) {
                assertEquals(expectedMessages[k], events.get(k).get(Line.MESSAGE_FIELD));
            }
            for (int k = events.size(); k < (events.size() + flushedEvents.size()); k++) {
                assertEquals(expectedMessages[k], flushedEvents.get(k - events.size()).get(Line.MESSAGE_FIELD));
            }
        }
    }

    private static Line getLineCodec(String delimiter, String charset) {
        Map<String, Object> config = new HashMap<>();
        if (delimiter != null) {
            config.put("delimiter", delimiter);
        }
        if (charset != null) {
            config.put("charset", charset);
        }
        return new Line(new ConfigurationImpl(config), new TestContext());
    }

    @Test
    public void testDecodeWithCharset() throws Exception {
        TestEventConsumer flushConsumer = new TestEventConsumer();

        // decode with cp-1252
        Line cp1252decoder = new Line(new ConfigurationImpl(Collections.singletonMap("charset", "cp1252")), new TestContext());
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};
        ByteBuffer b1 = ByteBuffer.wrap(rightSingleQuoteInCp1252);
        cp1252decoder.decode(b1, flushConsumer);
        assertEquals(0, flushConsumer.events.size());
        cp1252decoder.flush(b1, flushConsumer);
        assertEquals(1, flushConsumer.events.size());
        String fromCp1252 = (String) flushConsumer.events.get(0).get(Line.MESSAGE_FIELD);

        // decode with UTF-8
        flushConsumer.events.clear();
        Line utf8decoder = new Line(new ConfigurationImpl(Collections.emptyMap()), new TestContext());
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        ByteBuffer b2 = ByteBuffer.wrap(rightSingleQuoteInUtf8);
        utf8decoder.decode(b2, flushConsumer);
        assertEquals(0, flushConsumer.events.size());
        utf8decoder.flush(b2, flushConsumer);
        assertEquals(1, flushConsumer.events.size());
        String fromUtf8 = (String) flushConsumer.events.get(0).get(Line.MESSAGE_FIELD);
        assertEquals(fromCp1252, fromUtf8);
    }

    @Test
    public void testEncode() {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Line line = new Line(new ConfigurationImpl(Collections.emptyMap()), new TestContext());
        Event e = new Event();
        e.setField("myfield1", "myvalue1");
        e.setField("myfield2", 42L);
        line.encode(e, outputStream);
        e.setField("myfield1", "myvalue2");
        e.setField("myfield2", 43L);
        line.encode(e, outputStream);

        String delimiter = Line.DEFAULT_DELIMITER;
        String resultingString = outputStream.toString();
        // first delimiter should occur at the halfway point of the string
        assertEquals(resultingString.indexOf(delimiter), (resultingString.length() / 2) - delimiter.length());
        // second delimiter should occur at end of string
        assertEquals(resultingString.lastIndexOf(delimiter), resultingString.length() - delimiter.length());
    }

    @Test
    public void testEncodeWithCustomDelimiter() {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        String delimiter = "xyz";
        Line line = new Line(new ConfigurationImpl(Collections.singletonMap("delimiter", delimiter)), new TestContext());
        Event e = new Event();
        e.setField("myfield1", "myvalue1");
        e.setField("myfield2", 42L);
        line.encode(e, outputStream);
        e.setField("myfield1", "myvalue2");
        e.setField("myfield2", 43L);
        line.encode(e, outputStream);

        String resultingString = outputStream.toString();
        // first delimiter should occur at the halfway point of the string
        assertEquals(resultingString.indexOf(delimiter), (resultingString.length() / 2) - delimiter.length());
        // second delimiter should occur at end of string
        assertEquals(resultingString.lastIndexOf(delimiter), resultingString.length() - delimiter.length());
    }

    @Test
    public void testEncodeWithFormat() {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Line line = new Line(new ConfigurationImpl(Collections.singletonMap("format", "%{host}-%{message}")), new TestContext());
        String message = "Hello world";
        String host = "test";
        String expectedOutput = host + "-" + message + Line.DEFAULT_DELIMITER;
        Event e = new Event();
        e.setField("message", message);
        e.setField("host", host);

        line.encode(e, outputStream);

        String resultingString = outputStream.toString();
        assertEquals(expectedOutput, resultingString);
    }

}

class TestEventConsumer implements Consumer<Map<String, Object>> {

    List<Map<String, Object>> events = new ArrayList<>();

    @Override
    public void accept(Map<String, Object> stringObjectMap) {
        events.add(stringObjectMap);
    }
}

class TestContext implements Context {

    @Override
    public DeadLetterQueueWriter getDlqWriter() {
        return null;
    }

    @Override
    public Logger getLogger(Plugin plugin) {
        return null;
    }

}