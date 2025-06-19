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

import java.util.Iterator;
import java.util.List;

import static org.hamcrest.MatcherAssert.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.is;
import static org.hamcrest.Matchers.lessThan;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertThrows;
import static org.junit.Assert.assertTrue;
import static org.logstash.common.BufferedTokenizerTest.toList;

public final class BufferedTokenizerWithSizeLimitTest {

    private BufferedTokenizer sut;

    @Before
    public void setUp() {
        initSUTWithSizeLimit(10);
    }

    private void initSUTWithSizeLimit(int sizeLimit) {
        sut = new BufferedTokenizer("\n", sizeLimit);
    }

    @Test
    public void givenTokenWithinSizeLimitWhenExtractedThenReturnTokens() {
        List<String> tokens = toList(sut.extract("foo\nbar\n"));

        assertEquals(List.of("foo", "bar"), tokens);
    }

    @Test
    public void givenTokenExceedingSizeLimitWhenExtractedThenThrowsAnError() {
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract("this_is_longer_than_10\nkaboom").forEach(s -> {});
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));
    }

    @Test
    public void givenExtractedThrownLimitErrorWhenFeedFreshDataThenReturnTokenStartingFromEndOfOffendingToken() {
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            sut.extract("this_is_longer_than_10\nkaboom").forEach(s -> {});
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        List<String> tokens = toList(sut.extract("\nanother"));
        assertEquals("After buffer full error should resume from the end of line", List.of("kaboom"), tokens);
    }

    @Test
    public void givenExtractInvokedWithDifferentFramingAfterBufferFullErrorTWhenFeedFreshDataThenReturnTokenStartingFromEndOfOffendingToken() {
        sut.extract("aaaa");

        // it goes to 11 on a sizeLimit of 10, but doesn't trigger the exception till the next separator is reached
        sut.extract("aaaaaaa").forEach(s -> {});

        Iterable<String> tokenIterable = sut.extract("aa\nbbbb\nccc");
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            // now when querying and the next delimiter is present, the error is raised
            tokenIterable.forEach(s -> {});
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        // the iteration on token can proceed
        List<String> tokens = toList(tokenIterable);
        assertEquals(List.of("bbbb"), tokens);
    }

    @Test
    public void giveMultipleSegmentsThatGeneratesMultipleBufferFullErrorsThenIsAbleToRecoverTokenization() {
        sut.extract("aaaa");

        // it goes to 11 on a sizeLimit of 10, but doesn't trigger the exception till the next separator is reached
        sut.extract("aaaaaaa").forEach(s -> {});

        Iterable<String> tokenIterable = sut.extract("aa\nbbbbbbbbbbb\ncc");

        //first buffer full on 13 "a" letters
        Exception thrownException = assertThrows(IllegalStateException.class, () -> {
            tokenIterable.forEach(s -> {});
        });
        assertThat(thrownException.getMessage(), containsString("input buffer full"));

        // second buffer full on 11 "b" letters
        Exception secondThrownException = assertThrows(IllegalStateException.class, () -> {
            tokenIterable.forEach(s -> {});
        });
        assertThat(secondThrownException.getMessage(), containsString("input buffer full"));

        // now should resemble processing on c and d
        List<String> tokens = toList(sut.extract("ccc\nddd\n"));
        assertEquals(List.of("ccccc", "ddd"), tokens);
    }

    @Test
    public void givenFragmentThatHasTheSecondTokenOverrunsSizeLimitThenAnErrorIsThrown() {
        Iterable<String> tokensIterable = sut.extract("aaaa\nbbbbbbbbbbb\nccc\n");
        Iterator<String> tokensIterator = tokensIterable.iterator();

        // first token length = 4, it's ok
        assertEquals("aaaa", tokensIterator.next());

        // second token is an overrun, length = 11
        Exception exception = assertThrows(IllegalStateException.class, () -> {
            tokensIterator.next();
        });
        assertThat(exception.getMessage(), containsString("input buffer full"));

        // third token resumes
        assertEquals("ccc", tokensIterator.next());
    }

    @Test
    public void givenSequenceOfFragmentsWithoutSeparatorThenDoesntGenerateOutOfMemory() {
        final String neverEndingData = generate(8, "a");
        for (int i = 0; i < 10; i++) {
            sut.extract(neverEndingData);
        }

        // with the second fragment passed to extract it overrun the sizeLimit, the tokenizer
        // drop starting from the third fragment
        assertThat("Accumulator include only a part of an exploding payload", sut.flush().length(), is(lessThan(neverEndingData.length() * 3)));

        Iterable<String> tokensIterable = sut.extract("\nbbb\n");
        Iterator<String> tokensIterator = tokensIterable.iterator();
        // send a token delimiter and check is empty followed by 3 b's
        String emptyToken = tokensIterator.next();
        assertTrue(emptyToken.isEmpty());
        String validToken = tokensIterator.next();
        assertEquals("bbb", validToken);
    }

    private static String generate(int length, String fillChar) {
        return fillChar.repeat(length);
    }
}