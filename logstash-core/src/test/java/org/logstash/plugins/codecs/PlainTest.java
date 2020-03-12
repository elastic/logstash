/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins.codecs;

import co.elastic.logstash.api.Codec;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.plugins.ConfigurationImpl;
import org.logstash.plugins.TestContext;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.logstash.plugins.codecs.LineTest.compareMessages;

public class PlainTest {

    @Test
    public void testSimpleDecode() {
        String input = new String("abc".getBytes(), Charset.forName("UTF-8"));
        testDecode( null, input, 1, new String[]{input});
    }

    @Test
    public void testEmptyDecode() {
        String input = new String("".getBytes(), Charset.forName("UTF-8"));
        testDecode( null, input, 0, new String[]{});
    }

    @Test
    public void testDecodeWithUtf8() {
        String input = new String("München 安装中文输入法".getBytes(), Charset.forName("UTF-8"));
        testDecode(null, input, 1, new String[]{input});
    }

    @Test
    public void testDecodeWithCharset() {
        TestEventConsumer eventConsumer = new TestEventConsumer();

        // decode with cp-1252
        Plain cp1252decoder = new Plain(new ConfigurationImpl(Collections.singletonMap("charset", "cp1252")), new TestContext());
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};
        ByteBuffer b1 = ByteBuffer.wrap(rightSingleQuoteInCp1252);
        cp1252decoder.decode(b1, eventConsumer);
        assertEquals(1, eventConsumer.events.size());
        cp1252decoder.flush(b1, eventConsumer);
        assertEquals(1, eventConsumer.events.size());
        String fromCp1252 = (String) eventConsumer.events.get(0).get(Plain.MESSAGE_FIELD);

        // decode with UTF-8
        eventConsumer.events.clear();
        Plain utf8decoder = new Plain(new ConfigurationImpl(Collections.emptyMap()), new TestContext());
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        ByteBuffer b2 = ByteBuffer.wrap(rightSingleQuoteInUtf8);
        utf8decoder.decode(b2, eventConsumer);
        assertEquals(1, eventConsumer.events.size());
        utf8decoder.flush(b2, eventConsumer);
        assertEquals(1, eventConsumer.events.size());
        String fromUtf8 = (String) eventConsumer.events.get(0).get(Plain.MESSAGE_FIELD);
        assertEquals(fromCp1252, fromUtf8);
    }

    private void testDecode(String charset, String inputString, Integer expectedPreflushEvents, String[] expectedMessages) {
        Plain plain = getPlainCodec(charset);

        byte[] inputBytes = null;
        try {
            inputBytes = inputString.getBytes("UTF-8");
        } catch (UnsupportedEncodingException ex) {
            Assert.fail();
        }
        TestEventConsumer eventConsumer = new TestEventConsumer();
        ByteBuffer inputBuffer = ByteBuffer.wrap(inputBytes, 0, inputBytes.length);
        plain.decode(inputBuffer, eventConsumer);
        if (expectedPreflushEvents != null) {
            assertEquals(expectedPreflushEvents.intValue(), eventConsumer.events.size());
        }

        inputBuffer.compact();
        inputBuffer.flip();

        // flushing the plain codec should never produce events
        TestEventConsumer flushConsumer = new TestEventConsumer();
        plain.flush(inputBuffer, flushConsumer);
        assertEquals(0, flushConsumer.events.size());

        compareMessages(expectedMessages, eventConsumer.events, flushConsumer.events);
    }

    private static Plain getPlainCodec(String charset) {
        Map<String, Object> config = new HashMap<>();
        if (charset != null) {
            config.put("charset", charset);
        }
        return new Plain(new ConfigurationImpl(config), new TestContext());
    }

    @Test
    public void testEncodeWithUtf8() throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        String message = new String("München 安装中文输入法".getBytes(), Charset.forName("UTF-8"));
        Map<String, Object> config = new HashMap<>();
        config.put("format", "%{message}");
        Plain codec = new Plain(new ConfigurationImpl(config), new TestContext());
        Event e1 = new Event(Collections.singletonMap("message", message));
        codec.encode(e1, outputStream);
        Assert.assertEquals(message, new String(outputStream.toByteArray(), Charset.forName("UTF-8")));
    }

    @Test
    public void testEncodeWithCharset() throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        String rightSingleQuote = new String(rightSingleQuoteInUtf8, Charset.forName("UTF-8"));

        // encode with cp-1252
        Map<String, Object> config = new HashMap<>();
        config.put("charset", "cp1252");
        config.put("format", "%{message}");
        config.put("delimiter", "");
        Event e1 = new Event(Collections.singletonMap("message", rightSingleQuote));
        Plain cp1252encoder = new Plain(new ConfigurationImpl(config), new TestContext());
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};

        cp1252encoder.encode(e1, outputStream);
        byte[] resultBytes = outputStream.toByteArray();
        Assert.assertArrayEquals(rightSingleQuoteInCp1252, resultBytes);
    }

    @Test
    public void testEncodeWithFormat() throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        Plain encoder = new Plain(new ConfigurationImpl(Collections.singletonMap("format", "%{host}-%{message}")), null);
        String message = "Hello world";
        String host = "test";
        String expectedOutput = host + "-" + message;
        Event e = new Event();
        e.setField("message", message);
        e.setField("host", host);

        encoder.encode(e, outputStream);

        String resultingString = outputStream.toString();
        assertEquals(expectedOutput, resultingString);
    }

    @Test
    public void testClone() throws IOException  {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        String charset = "cp1252";
        byte[] rightSingleQuoteInUtf8 = {(byte) 0xE2, (byte) 0x80, (byte) 0x99};
        String rightSingleQuote = new String(rightSingleQuoteInUtf8, Charset.forName("UTF-8"));

        // encode with cp-1252
        Map<String, Object> config = new HashMap<>();
        config.put("charset", charset);
        config.put("format", "%{message}");
        Event e1 = new Event(Collections.singletonMap("message", rightSingleQuote));
        Plain codec = new Plain(new ConfigurationImpl(config), new TestContext());

        // clone codec
        Codec clone = codec.cloneCodec();
        Assert.assertEquals(codec.getClass(), clone.getClass());
        Plain plain2 = (Plain)clone;

        // verify charset and delimiter
        byte[] rightSingleQuoteInCp1252 = {(byte) 0x92};
        plain2.encode(e1, outputStream);
        Assert.assertArrayEquals(rightSingleQuoteInCp1252, outputStream.toByteArray());
    }

}
