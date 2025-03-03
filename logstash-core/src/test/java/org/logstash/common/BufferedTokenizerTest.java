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

package org.logstash.common;

import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

public final class BufferedTokenizerTest {

    private BufferedTokenizer sut;

    static List<String> toList(Iterable<String> iter) {
        List<String> acc = new ArrayList<>();
        iter.forEach(acc::add);
        return acc;
    }

    @Before
    public void setUp() {
        sut = new BufferedTokenizer();
    }

    @Test
    public void shouldTokenizeASingleToken() {
        List<String> tokens = toList(sut.extract("foo\n"));

        assertEquals(List.of("foo"), tokens);
    }

    @Test
    public void shouldMergeMultipleToken() {
        List<String> tokens = toList(sut.extract("foo"));
        assertTrue(tokens.isEmpty());

        tokens = toList(sut.extract("bar\n"));
        assertEquals(List.of("foobar"), tokens);
    }

    @Test
    public void shouldTokenizeMultipleToken() {
        List<String> tokens = toList(sut.extract("foo\nbar\n"));

        assertEquals(List.of("foo", "bar"), tokens);
    }

    @Test
    public void shouldIgnoreEmptyPayload() {
        List<String> tokens = toList(sut.extract(""));
        assertTrue(tokens.isEmpty());

        tokens = toList(sut.extract("foo\nbar"));
        assertEquals(List.of("foo"), tokens);
    }

    @Test
    public void shouldTokenizeEmptyPayloadWithNewline() {
        List<String> tokens = toList(sut.extract("\n"));
        assertEquals(List.of(""), tokens);

        tokens = toList(sut.extract("\n\n\n"));
        assertEquals(List.of("", "", ""), tokens);
    }

//    @Test
//    public void shouldNotChangeEncodingOfTokensAfterPartitioning() {
//        RubyString rubyString = RubyString.newString(RUBY, new byte[]{(byte) 0xA3, 0x0A, 0x41}); // £ character, newline, A
//        IRubyObject rubyInput = rubyString.force_encoding(context, RUBY.newString("ISO8859-1"));
//        RubyArray<RubyString> tokens = (RubyArray<RubyString>)sut.extract(context, rubyInput);
//
//        // read the first token, the £ string
//        IRubyObject firstToken = tokens.shift(context);
//        assertEquals("£", firstToken.toString());
//
//        // verify encoding "ISO8859-1" is preserved in the Java to Ruby String conversion
//        RubyEncoding encoding = (RubyEncoding) firstToken.callMethod(context, "encoding");
//        assertEquals("ISO-8859-1", encoding.toString());
//    }
//
//    @Test
//    public void shouldNotChangeEncodingOfTokensAfterPartitioningInCaseMultipleExtractionInInvoked() {
//        RubyString rubyString = RubyString.newString(RUBY, new byte[]{(byte) 0xA3}); // £ character
//        IRubyObject rubyInput = rubyString.force_encoding(context, RUBY.newString("ISO8859-1"));
//        sut.extract(context, rubyInput);
//        IRubyObject capitalAInLatin1 = RubyString.newString(RUBY, new byte[]{(byte) 0x41})
//                .force_encoding(context, RUBY.newString("ISO8859-1"));
//        RubyArray<RubyString> tokens = (RubyArray<RubyString>)sut.extract(context, capitalAInLatin1);
//        assertTrue(tokens.isEmpty());
//
//        tokens = (RubyArray<RubyString>)sut.extract(context, RubyString.newString(RUBY, new byte[]{(byte) 0x0A}));
//
//        // read the first token, the £ string
//        IRubyObject firstToken = tokens.shift(context);
//        assertEquals("£A", firstToken.toString());
//
//        // verify encoding "ISO8859-1" is preserved in the Java to Ruby String conversion
//        RubyEncoding encoding = (RubyEncoding) firstToken.callMethod(context, "encoding");
//        assertEquals("ISO-8859-1", encoding.toString());
//    }
//
//    @Test
//    public void shouldNotChangeEncodingOfTokensAfterPartitioningWhenRetrieveLastFlushedToken() {
//        RubyString rubyString = RubyString.newString(RUBY, new byte[]{(byte) 0xA3, 0x0A, 0x41}); // £ character, newline, A
//        IRubyObject rubyInput = rubyString.force_encoding(context, RUBY.newString("ISO8859-1"));
//        RubyArray<RubyString> tokens = (RubyArray<RubyString>)sut.extract(context, rubyInput);
//
//        // read the first token, the £ string
//        IRubyObject firstToken = tokens.shift(context);
//        assertEquals("£", firstToken.toString());
//
//        // flush and check that the remaining A is still encoded in ISO8859-1
//        IRubyObject lastToken = sut.flush(context);
//        assertEquals("A", lastToken.toString());
//
//        // verify encoding "ISO8859-1" is preserved in the Java to Ruby String conversion
//        RubyEncoding encoding = (RubyEncoding) lastToken.callMethod(context, "encoding");
//        assertEquals("ISO-8859-1", encoding.toString());
//    }
//
//    @Test
//    public void givenDirectFlushInvocationUTF8EncodingIsApplied() {
//        RubyString rubyString = RubyString.newString(RUBY, new byte[]{(byte) 0xA3, 0x41}); // £ character, A
//        IRubyObject rubyInput = rubyString.force_encoding(context, RUBY.newString("ISO8859-1"));
//
//        // flush and check that the remaining A is still encoded in ISO8859-1
//        IRubyObject lastToken = sut.flush(context);
//        assertEquals("", lastToken.toString());
//
//        // verify encoding "ISO8859-1" is preserved in the Java to Ruby String conversion
//        RubyEncoding encoding = (RubyEncoding) lastToken.callMethod(context, "encoding");
//        assertEquals("UTF-8", encoding.toString());
//    }
}