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

import static org.junit.Assert.*;

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

    @Test
    public void givenBufferWithTerminatedAndUnterminatedTokensWhenCheckingForEmptyThenReturnFalseIfUnterminatedTokenPartRemainInTheBuffer() {
        List<String> tokens = toList(sut.extract("foo\nbar\nbaz"));
        assertEquals(List.of("foo", "bar"), tokens);

        assertFalse("Unterminated token makes the buffer to be considered non empty", sut.isEmpty());
    }
}