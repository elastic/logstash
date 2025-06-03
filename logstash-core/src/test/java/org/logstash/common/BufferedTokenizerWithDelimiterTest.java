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

import java.util.List;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.logstash.common.BufferedTokenizerTest.toList;

public final class BufferedTokenizerWithDelimiterTest {

    private BufferedTokenizer sut;

    @Before
    public void setUp() {
        sut = new BufferedTokenizer("||");
    }

    @Test
    public void shouldTokenizeMultipleToken() {
        List<String> tokens = toList(sut.extract("foo||b|r||"));

        assertEquals(List.of("foo", "b|r"), tokens);
    }

    @Test
    public void shouldIgnoreEmptyPayload() {
        List<String> tokens = toList(sut.extract(""));
        assertTrue(tokens.isEmpty());

        tokens = toList(sut.extract("foo||bar"));
        assertEquals(List.of("foo"), tokens);
    }
}
