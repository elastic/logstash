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

import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyUtil;

import java.util.Arrays;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.logstash.RubyUtil.RUBY;

@SuppressWarnings("unchecked")
public final class BufferedTokenizerExtTest {

    private BufferedTokenizerExt sut;
    private ThreadContext context;

    @Before
    public void setUp() {
        sut = new BufferedTokenizerExt(RubyUtil.RUBY, RubyUtil.BUFFERED_TOKENIZER);
        context = RUBY.getCurrentContext();
        IRubyObject[] args = {};
        sut.init(context, args);
    }

    @Test
    public void shouldTokenizeASingleToken() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("foo\n"));

        assertEquals(Arrays.asList("foo"), tokens);
    }

    @Test
    public void shouldMergeMultipleToken() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("foo"));
        assertTrue(tokens.isEmpty());

        tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("bar\n"));
        assertEquals(Arrays.asList("foobar"), tokens);
    }

    @Test
    public void shouldTokenizeMultipleToken() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("foo\nbar\n"));

        assertEquals(Arrays.asList("foo", "bar"), tokens);
    }

    @Test
    public void shouldIgnoreEmptyPayload() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString(""));
        assertTrue(tokens.isEmpty());

        tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("foo\nbar"));
        assertEquals(Arrays.asList("foo"), tokens);
    }

    @Test
    public void shouldTokenizeEmptyPayloadWithNewline() {
        RubyArray<RubyString> tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("\n"));
        assertEquals(Arrays.asList(""), tokens);

        tokens = (RubyArray<RubyString>) sut.extract(context, RubyUtil.RUBY.newString("\n\n\n"));
        assertEquals(Arrays.asList("", "", ""), tokens);
    }
}