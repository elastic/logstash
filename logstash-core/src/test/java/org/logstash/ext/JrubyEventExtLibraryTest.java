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


package org.logstash.ext;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import org.assertj.core.api.Assertions;
import org.hamcrest.CoreMatchers;
import org.jruby.RubyBoolean;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.exceptions.RuntimeError;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Assert;
import org.junit.Test;
import org.logstash.ObjectMappers;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;

/**
 * Tests for {@link JrubyEventExtLibrary.RubyEvent}.
 */
public final class JrubyEventExtLibraryTest extends RubyTestBase {

    @Test
    public void shouldSetJavaProxy() throws IOException {
        for (final Object proxy : Arrays.asList(getMapFixtureJackson(), getMapFixtureHandcrafted())) {
            final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
            final JrubyEventExtLibrary.RubyEvent event =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime);
            event.ruby_set_field(
                context, rubyString("[proxy]"),
                JavaUtil.convertJavaToUsableRubyObject(context.runtime, proxy)
            );
            final Map<String, IRubyObject> expected = new HashMap<>();
            expected.put("[string]", rubyString("foo"));
            expected.put("[int]", context.runtime.newFixnum(42));
            expected.put("[float]", context.runtime.newFloat(42.42));
            expected.put("[array][0]", rubyString("bar"));
            expected.put("[array][1]", rubyString("baz"));
            expected.put("[hash][string]", rubyString("quux"));
            expected.forEach(
                (key, value) -> Assertions.assertThat(
                    event.ruby_get_field(context, rubyString("[proxy]" + key))
                ).isEqualTo(value)
            );
        }
    }

    @Test
    public void correctlyHandlesNonAsciiKeys() {
        final RubyString key = rubyString("[テストフィールド]");
        final RubyString value = rubyString("someValue");
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyEventExtLibrary.RubyEvent event =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime);
        event.ruby_set_field(context, key, value);
        Assertions.assertThat(event.ruby_to_json(context, new IRubyObject[0]).asJavaString())
            .contains("\"テストフィールド\":\"someValue\"");
    }

    @Test
    public void correctlyRaiseRubyRuntimeErrorWhenGivenInvalidFieldReferences() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyEventExtLibrary.RubyEvent event =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime);
        final RubyString key = rubyString("il[[]]]legal");
        final RubyString value = rubyString("foo");
        try {
            event.ruby_set_field(context, key, value);
        } catch (RuntimeError rubyRuntimeError) {
            Assert.assertThat(rubyRuntimeError.getLocalizedMessage(), CoreMatchers.containsString("Invalid FieldReference"));
            return;
        }
        Assert.fail("expected ruby RuntimeError was not thrown.");
    }

    @Test
    public void correctlySetsValueWhenGivenMapWithKeysThatHaveFieldReferenceSpecialCharacters() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyEventExtLibrary.RubyEvent event =
                JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime);
        final RubyString key = rubyString("foo");
        final RubyHash value = RubyHash.newHash(context.runtime, Collections.singletonMap(rubyString("il[[]]]legal"), rubyString("okay")), context.nil);

        event.ruby_set_field(context, key, value);
        IRubyObject retrievedValue = event.ruby_get_field(context, key);
        Assert.assertThat(retrievedValue, CoreMatchers.equalTo(value));

        RubyHash eventHash = (RubyHash) event.ruby_to_hash_with_metadata(context);
        IRubyObject nestedValue = eventHash.dig(context, rubyString("foo"), rubyString("il[[]]]legal"));
        Assert.assertFalse(nestedValue.isNil());
        Assert.assertEquals(rubyString("okay"), nestedValue);
    }

    private static RubyString rubyString(final String java) {
        return RubyUtil.RUBY.newString(java);
    }

    private static Object getMapFixtureJackson() throws IOException {
        StringBuilder json = new StringBuilder();
        json.append('{');
        json.append("\"string\": \"foo\", ");
        json.append("\"int\": 42, ");
        json.append("\"float\": 42.42, ");
        json.append("\"array\": [\"bar\",\"baz\"], ");
        json.append("\"hash\": {\"string\":\"quux\"} }");
        return ObjectMappers.JSON_MAPPER.readValue(json.toString(), Object.class);
    }

    private static Map<String, Object> getMapFixtureHandcrafted() {
        HashMap<String, Object> inner = new HashMap<>();
        inner.put("string", "quux");
        HashMap<String, Object> map = new HashMap<>();
        map.put("string", "foo");
        map.put("int", 42);
        map.put("float", 42.42);
        map.put("array", Arrays.asList("bar", "baz"));
        map.put("hash", inner);
        return map;
    }
}
