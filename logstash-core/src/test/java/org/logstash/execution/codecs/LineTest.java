package org.logstash.execution.codecs;

import org.junit.Test;
import org.logstash.Event;
import org.logstash.execution.LsConfiguration;

import java.io.ByteArrayOutputStream;
import java.lang.reflect.Array;
import java.nio.ByteBuffer;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class LineTest {

    @Test
    public void testSimpleDecode() {
        String input = "abc";
        testDecode(null, null, input, 0, 1, new String[] {input});
    }

    @Test
    public void testDecodeDefaultDelimiter() {
        String[] inputStrings = {"foo", "bar", "baz"};
        String input = String.join(System.lineSeparator(), inputStrings);

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
        testDecode(null, null, input + System.lineSeparator(), 1, 0, new String[]{input});
    }

    @Test
    public void testDecodeAcrossMulticharBoundary() {

    }

    @Test
    public void testFlush() {
        String[] inputs = {"The", "quick", "brown", "fox", "jumps"};
        String input = String.join(System.lineSeparator(), inputs);
        int bufferSize = 2;
        testDecode(null, null, input, bufferSize, inputs.length - bufferSize, inputs, bufferSize);
    }

    private void testDecode(String delimiter, String charset, String inputString, Integer expectedPreflushEvents, Integer expectedFlushEvents, String[] expectedMessages) {
        testDecode(delimiter, charset, inputString, expectedPreflushEvents, expectedFlushEvents, expectedMessages, null);
    }

    private void testDecode(String delimiter, String charset, String inputString, Integer expectedPreflushEvents, Integer expectedFlushEvents, String[] expectedMessages, Integer bufferSize) {
        // construct codec with specified config values
        Map<String, String> config = new HashMap<>();
        if (delimiter != null) {
            config.put("delimiter", delimiter);
        }
        if (charset != null) {
            config.put("charset", charset);
        }
        Line line = new Line(new LsConfiguration(config), null);

        int bufSize = bufferSize != null
                ? bufferSize
                : expectedPreflushEvents == null ? 10 : expectedPreflushEvents + 1;
        Map<String, Object>[] events =
                (HashMap<String, Object>[]) Array.newInstance(new HashMap<String, Object>().getClass(), bufSize);

        byte[] inputBytes = inputString.getBytes();
        ByteBuffer inputBuffer = ByteBuffer.wrap(inputBytes, 0, inputBytes.length);
        int num = line.decode(inputBuffer, events);
        if (expectedPreflushEvents != null) {
            assertEquals(expectedPreflushEvents.intValue(), num);
        }

        if (inputBuffer.position() == inputBuffer.limit()) {
            inputBuffer.clear();
        } else {
            inputBuffer.compact();
        }
        inputBuffer.flip();

        Map<String, Object>[] flushEvents = line.flush(inputBuffer);
        if (expectedFlushEvents != null) {
            assertEquals(expectedFlushEvents.intValue(), flushEvents.length);
        }

        if (expectedMessages != null) {
            for (int k = 0; k < num; k++) {
                assertEquals(expectedMessages[k], events[k].get(Line.MESSAGE_FIELD));
            }
            for (int k = num; k < (num + flushEvents.length); k++) {
                assertEquals(expectedMessages[k], flushEvents[k - num].get(Line.MESSAGE_FIELD));
            }
        }
    }


    @Test
    public void testDecodeWithCharset() throws Exception {
        Map<String, Object>[] events =
                (HashMap<String, Object>[]) Array.newInstance(new HashMap<String, Object>().getClass(), 2);
        Map<String, Object>[] flushEvents;

        Line cp1252decoder = new Line(new LsConfiguration(Collections.singletonMap("charset", "cp1252")), null);
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};
        ByteBuffer b1 = ByteBuffer.wrap(rightSingleQuoteInCp1252);
        assertEquals(0, cp1252decoder.decode(b1, events));
        flushEvents = cp1252decoder.flush(b1);
        assertEquals(1, flushEvents.length);
        String fromCp1252 = (String)flushEvents[0].get(Line.MESSAGE_FIELD);
        Line utf8decoder = new Line(new LsConfiguration(Collections.EMPTY_MAP), null);
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        ByteBuffer b2 = ByteBuffer.wrap(rightSingleQuoteInUtf8);
        assertEquals(0, utf8decoder.decode(b2, events));
        flushEvents = utf8decoder.flush(b2);
        assertEquals(1, flushEvents.length);
        String fromUtf8 = (String)flushEvents[0].get(Line.MESSAGE_FIELD);
        assertEquals(fromCp1252, fromUtf8);
    }

    @Test
    public void testEncode() {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Line line = new Line(new LsConfiguration(Collections.emptyMap()), null);
        Event e = new Event();
        e.setField("myfield1", "myvalue1");
        e.setField("myfield2", 42L);
        line.encode(e, outputStream);
        e.setField("myfield1", "myvalue2");
        e.setField("myfield2", 43L);
        line.encode(e, outputStream);

        String delimiter = System.lineSeparator();
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
        Line line = new Line(new LsConfiguration(Collections.singletonMap("delimiter", delimiter)), null);
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
        Line line = new Line(new LsConfiguration(Collections.singletonMap("format", "%{host}-%{message}")), null);
        String message = "Hello world";
        String host = "test";
        String expectedOutput = host + "-" + message + System.lineSeparator();
        Event e = new Event();
        e.setField("message", message);
        e.setField("host", host);

        line.encode(e, outputStream);

        String resultingString = outputStream.toString();
        assertEquals(expectedOutput, resultingString);
    }

}
