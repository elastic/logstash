package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.TestContext;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
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
        String input = new String("abc".getBytes(), Charset.forName("UTF-8"));
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
        String delimiter = System.lineSeparator();
        String[] inputs = {"foo", "bar", "baz"};
        String input = String.join(delimiter, inputs) + delimiter;

        testDecode(null, null, input, inputs.length, 0, inputs);
    }

    @Test
    public void testSuccessiveDecodesWithTrailingDelimiter() {
        // setup inputs
        String delimiter = System.lineSeparator();
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
        String input = new String("München 安装中文输入法".getBytes(), Charset.forName("UTF-8"));
        testDecode(null, null, input + Line.DEFAULT_DELIMITER, 1, 0, new String[]{input});
    }

    @Test
    public void testDecodeAcrossMultibyteCharBoundary() throws Exception {
        final int BUFFER_SIZE = 12;
        int lastPos = 0;
        TestEventConsumer eventConsumer = new TestEventConsumer();
        String delimiter = System.lineSeparator();
        String input = new String(("安安安" + delimiter + "安安安" + delimiter + "安安安").getBytes(), Charset.forName("UTF-8"));
        byte[] bytes = input.getBytes("UTF-8");
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

        byte[] inputBytes = null;
        try {
            inputBytes = inputString.getBytes("UTF-8");
        } catch (UnsupportedEncodingException ex) {
            Assert.fail();
        }
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
    public void testEncode() throws Codec.EncodeException {
        String delimiter = "z";
        String message = "Hello world";
        String expectedResult = message + delimiter;
        Map<String, Object> config = new HashMap<>();
        config.put("delimiter", delimiter);
        config.put("format", "%{message}");
        Line line = new Line(new ConfigurationImpl(config), new TestContext());
        Event e = new Event(Collections.singletonMap("message", message));
        byte[] b = new byte[100];
        ByteBuffer buffer = ByteBuffer.wrap(b);
        boolean result = line.encode(e, buffer);
        Assert.assertTrue(result);
        String resultString = new String(buffer.array(), buffer.position(), buffer.limit());
        Assert.assertEquals(expectedResult, resultString);
    }

    @Test
    public void testMultipleEncodesForEvent() throws Codec.EncodeException {
        String delimiter = "z";
        String message = "Hello world";
        String expectedResult = message + delimiter;
        Map<String, Object> config = new HashMap<>();
        config.put("delimiter", delimiter);
        config.put("format", "%{message}");
        Line line = new Line(new ConfigurationImpl(config), new TestContext());
        Event e = new Event(Collections.singletonMap("message", message));
        byte[] b = new byte[10];
        ByteBuffer buffer = ByteBuffer.wrap(b);

        boolean result = line.encode(e, buffer);
        Assert.assertFalse(result);
        String resultString = new String(buffer.array(), buffer.position(), buffer.limit());

        buffer.clear();
        result = line.encode(e, buffer);
        Assert.assertTrue(result);
        resultString += new String(buffer.array(), buffer.position(), buffer.limit());

        Assert.assertEquals(expectedResult, resultString);
    }

    @Test
    public void testEncodeNewEventBeforeFinishingPreviousThrows() {
        String delimiter = "z";
        String message = "Hello world";
        Map<String, Object> config = new HashMap<>();
        config.put("delimiter", delimiter);
        config.put("format", "%{message}");
        Line line = new Line(new ConfigurationImpl(config), new TestContext());
        Event e1 = new Event(Collections.singletonMap("message", message));
        Event e2 = new Event(Collections.singletonMap("message", message));
        byte[] b = new byte[10];
        ByteBuffer buffer = ByteBuffer.wrap(b);
        try {
            line.encode(e1, buffer);
            line.encode(e2, buffer);
            Assert.fail("EncodeException should be thrown because previous event was not fully encoded");
        } catch (Codec.EncodeException ex) {
            // this exception should be thrown
        }
    }

    @Test
    public void testEncodeWithUtf8() throws Codec.EncodeException {
        String delimiter = "z";
        String message = new String("München 安装中文输入法".getBytes(), Charset.forName("UTF-8"));
        Map<String, Object> config = new HashMap<>();
        config.put("delimiter", delimiter);
        config.put("format", "%{message}");
        Line line = new Line(new ConfigurationImpl(config), new TestContext());
        Event e1 = new Event(Collections.singletonMap("message", message));
        byte[] b = new byte[100];
        ByteBuffer buffer = ByteBuffer.wrap(b);
        boolean result = line.encode(e1, buffer);
        Assert.assertTrue(result);
        String expectedResult = message + delimiter;
        Assert.assertEquals(expectedResult, new String(buffer.array(), buffer.position(), buffer.limit(), Charset.forName("UTF-8")));
    }

    @Test
    public void testEncodeAcrossMultibyteCharBoundary() throws Codec.EncodeException {
        String message = new String("安安安安安安安安安".getBytes(), Charset.forName("UTF-8"));
        String delimiter = "";
        Map<String, Object> config = new HashMap<>();
        config.put("delimiter", delimiter);
        config.put("format", "%{message}");
        Line line = new Line(new ConfigurationImpl(config), new TestContext());
        Event e1 = new Event(Collections.singletonMap("message", message));
        byte[] b = new byte[10];
        ByteBuffer buffer = ByteBuffer.wrap(b);

        boolean result = line.encode(e1, buffer);
        String intermediateResult = new String(buffer.array(), buffer.position(), buffer.limit());
        Assert.assertFalse(result);
        Assert.assertEquals("安安安", intermediateResult);

        buffer.clear();
        result = line.encode(e1, buffer);
        intermediateResult = new String(buffer.array(), buffer.position(), buffer.limit());
        Assert.assertFalse(result);
        Assert.assertEquals("安安安", intermediateResult);

        buffer.clear();
        result = line.encode(e1, buffer);
        intermediateResult = new String(buffer.array(), buffer.position(), buffer.limit());
        Assert.assertTrue(result);
        Assert.assertEquals("安安安", intermediateResult);
    }


    @Test
    public void testEncodeWithCharset() throws Exception {
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        String rightSingleQuote = new String(rightSingleQuoteInUtf8, Charset.forName("UTF-8"));

        // encode with cp-1252
        Map<String, Object> config = new HashMap<>();
        config.put("charset", "cp1252");
        config.put("format", "%{message}");
        config.put("delimiter", "");
        Event e1 = new Event(Collections.singletonMap("message", rightSingleQuote));
        Line cp1252decoder = new Line(new ConfigurationImpl(config), new TestContext());
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};
        byte[] b = new byte[100];
        ByteBuffer buffer = ByteBuffer.wrap(b);

        boolean result = cp1252decoder.encode(e1, buffer);
        Assert.assertTrue(result);
        byte[] resultBytes = new byte[buffer.limit() - buffer.position()];
        System.arraycopy(buffer.array(), buffer.position(), resultBytes, 0, buffer.limit() - buffer.position());
        Assert.assertArrayEquals(rightSingleQuoteInCp1252, resultBytes);
    }

    @Test
    public void testClone() throws Codec.EncodeException {
        String delimiter = "x";
        String charset = "cp1252";
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        String rightSingleQuote = new String(rightSingleQuoteInUtf8, Charset.forName("UTF-8"));

        // encode with cp-1252
        Map<String, Object> config = new HashMap<>();
        config.put("charset", charset);
        config.put("format", "%{message}");
        config.put("delimiter", delimiter);
        Event e1 = new Event(Collections.singletonMap("message", rightSingleQuote));
        Line codec = new Line(new ConfigurationImpl(config), new TestContext());

        // clone codec
        Codec clone = codec.cloneCodec();
        Assert.assertEquals(codec.getClass(), clone.getClass());
        Line line2 = (Line)clone;

        // verify charset and delimiter
        byte[] rightSingleQuoteAndXInCp1252 = {(byte) 0x92, (byte) 0x78};
        byte[] b = new byte[100];
        ByteBuffer buffer = ByteBuffer.wrap(b);

        boolean result = line2.encode(e1, buffer);
        Assert.assertTrue(result);
        byte[] resultBytes = new byte[buffer.limit() - buffer.position()];
        System.arraycopy(buffer.array(), buffer.position(), resultBytes, 0, buffer.limit() - buffer.position());
        Assert.assertArrayEquals(rightSingleQuoteAndXInCp1252, resultBytes);
    }

}

class TestEventConsumer implements Consumer<Map<String, Object>> {

    List<Map<String, Object>> events = new ArrayList<>();

    @Override
    public void accept(Map<String, Object> stringObjectMap) {
        events.add(new HashMap<>(stringObjectMap));
    }
}
