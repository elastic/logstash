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


package org.logstash;

import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.junit.Test;

import static org.junit.Assert.*;

public class ClonerTest extends RubyTestBase {
    @Test
    public void testRubyStringCloning() {
        String javaString = "fooBar";
        RubyString original = RubyString.newString(RubyUtil.RUBY, javaString);

        RubyString result = Cloner.deep(original);
        // Check object identity
        assertNotSame(original, result);
        // Check string equality
        assertEquals(original, result);

        assertEquals(javaString, result.asJavaString());
    }

    @Test
    public void testRubyStringCloningAndAppend() {
        String javaString = "fooBar";
        RubyString original = RubyString.newString(RubyUtil.RUBY, javaString);

        RubyString result = Cloner.deep(original);

        result.append(RubyUtil.RUBY.newString("X"));

        assertNotEquals(result, original);

        ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        assertTrue(original.op_equal(context, RubyString.newString(RubyUtil.RUBY, javaString)).isTrue());
        assertEquals(javaString, original.asJavaString());
    }

    @Test
    public void testRubyStringCloningAndChangeOriginal() {
        String javaString = "fooBar";
        RubyString original = RubyString.newString(RubyUtil.RUBY, javaString);

        RubyString result = Cloner.deep(original);

        ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        IRubyObject index = RubyUtil.RUBY.newFixnum(5);
        original.op_aset(context, index, RubyUtil.RUBY.newString("z")); // original[5] = 'z'

        assertNotEquals(result, original);

        assertTrue(result.op_equal(context, RubyString.newString(RubyUtil.RUBY, javaString)).isTrue());
        assertEquals(javaString, result.asJavaString());
        assertEquals("fooBaz", original.asJavaString());
    }

    @Test // @Tag("Performance Optimization")
    public void testRubyStringCloningMemoryOptimization() {
        ByteList bytes = ByteList.create("0123456789");
        RubyString original = RubyString.newString(RubyUtil.RUBY, bytes);

        RubyString result = Cloner.deep(original);
        assertNotSame(original, result);

        assertSame(bytes, original.getByteList());
        // NOTE: this is an implementation detail or the underlying sharing :
        assertSame(bytes, result.getByteList()); // bytes-list shared

        // but when string is modified it will stop using the same byte container
        result.concat(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newString(" "));
        assertNotSame(bytes, result.getByteList()); // byte-list copied on write
    }
}