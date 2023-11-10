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


package org.logstash.log;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.module.SimpleModule;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubySymbol;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import static junit.framework.TestCase.assertEquals;
import static junit.framework.TestCase.assertTrue;
import static org.logstash.RubyUtil.*;

public class RubyBasicObjectSerializerTest {
    private final ObjectMapper mapper = new ObjectMapper().registerModule(new SimpleModule().addSerializer(new RubyBasicObjectSerializer()));

    @Test
    public void testSerializerPriority() throws JsonProcessingException {
        final String expectedOutput = "value_from_custom_serializer";

        mapper.registerModule(new SimpleModule().addSerializer(new StdSerializer<>(RubySymbol.class) {
            private static final long serialVersionUID = 2531452116050620859L;

            @Override
            public void serialize(RubySymbol value, JsonGenerator gen, SerializerProvider provider) throws IOException {
                gen.writeRawValue(expectedOutput);
            }
        }));

        final RubySymbol symbol = RubySymbol.newSymbol(RUBY, "value");
        final String serializedValue = mapper.writeValueAsString(symbol);

        assertEquals(expectedOutput, serializedValue);
    }

    @Test
    public void testSerializationWithJavaListValue() throws JsonProcessingException {
        final String listSerializedValue = mapper.writeValueAsString(List.of(RubySymbol.newSymbol(RUBY, "foo"), RubySymbol.newSymbol(RUBY, "bar")));

        final List<String> values = mapper.readerForListOf(String.class).readValue(listSerializedValue);
        assertEquals(2, values.size());
        assertTrue(values.containsAll(List.of("foo", "bar")));
    }

    @Test
    public void testSerializationWithRubyArrayValue() throws JsonProcessingException {
        final RubyArray<RubySymbol> rubyArray = new RubyArray<>(RUBY, 2);
        rubyArray.push(RubySymbol.newSymbol(RUBY, "one"));
        rubyArray.push(RubySymbol.newSymbol(RUBY, "two"));

        final String listSerializedValue = mapper.writeValueAsString(rubyArray);

        final List<String> values = mapper.readerForListOf(String.class).readValue(listSerializedValue);
        assertEquals(2, values.size());
        assertTrue(values.containsAll(List.of("one", "two")));
    }

    @Test
    public void testSerializationWithArrayValue() throws JsonProcessingException {
        final RubySymbol[] array = new RubySymbol[]{RubySymbol.newSymbol(RUBY, "one"), RubySymbol.newSymbol(RUBY, "two")};

        final String arraySerializedValue = mapper.writeValueAsString(array);

        final List<String> values = mapper.readerForListOf(String.class).readValue(arraySerializedValue);
        assertEquals(2, values.size());
        assertTrue(values.containsAll(List.of("one", "two")));
    }

    @Test
    public void testSerializationWithRubyMapValue() throws JsonProcessingException {
        final RubyHash rubyHash = RubyHash.newHash(RUBY);
        rubyHash.put("1", RubySymbol.newSymbol(RUBY, "one"));
        rubyHash.put("2", RubySymbol.newSymbol(RUBY, "two"));

        final String listSerializedValue = mapper.writeValueAsString(rubyHash);

        final Map<String, String> values = mapper.readerForMapOf(String.class).readValue(listSerializedValue);

        assertEquals(2, values.size());
        assertEquals("one", values.get("1"));
        assertEquals("two", values.get("2"));
    }

    @Test
    public void testValueWithNoCustomInspectMethod() throws JsonProcessingException {
        final IRubyObject rubyObject = createRubyObject(null, "'value_from_to_s'", null);

        final String result = mapper.writeValueAsString(rubyObject);

        assertEquals("\"value_from_to_s\"", result);
    }

    @Test
    public void testLogstashOwnedValueWithNoCustomInspectMethod() throws JsonProcessingException {
        final IRubyObject rubyObject = createRubyObject("Logstash", "'value_from_to_s'", null);

        final String result = mapper.writeValueAsString(rubyObject);

        assertEquals("\"value_from_to_s\"", result);
    }

    @Test
    public void testLogstashOwnedValueWithCustomInspectMethod() throws JsonProcessingException {
        final IRubyObject rubyObject = createRubyObject("Logstash", "'value_from_to_s'", "'value_from_inspect'");

        final String result = mapper.writeValueAsString(rubyObject);

        assertEquals("\"value_from_inspect\"", result);
    }

    @Test
    public void testFailingInspectMethodFallback() throws JsonProcessingException {
        final IRubyObject rubyObject = createRubyObject("Logstash", "'value_from_to_s'", "@called = true\n raise 'not ok'");

        final String result = mapper.writeValueAsString(rubyObject);

        boolean inspectCalled = rubyObject.getInstanceVariables().getInstanceVariable("@called").toJava(Boolean.class);

        assertTrue(inspectCalled);
        assertEquals("\"value_from_to_s\"", result);
    }

    @Test
    public void testFailingToSMethodFallback() throws JsonProcessingException {
        final IRubyObject rubyObject = createRubyObject("Logstash", "@called = true\n raise 'mayday!'", null);

        final String result = mapper.writeValueAsString(rubyObject);

        boolean toSCalled = rubyObject.getInstanceVariables().getInstanceVariable("@called").toJava(Boolean.class);

        assertTrue(toSCalled);
        assertTrue(result.startsWith("\"#<Logstash::Test:"));
    }

    private IRubyObject createRubyObject(final String moduleName, final String toSBody, final String inspectBody) {
        final StringBuilder sb = new StringBuilder();
        if (moduleName != null) {
            sb.append(String.format("module %s\n", moduleName));
        }

        sb.append("class Test\n");
        if (toSBody != null) {
            sb.append(String.format("def to_s\n %s \nend\n", toSBody));
        }

        if (inspectBody != null) {
            sb.append(String.format("def inspect\n %s \nend\n", inspectBody));
        }

        sb.append("end\n");

        if (moduleName != null) {
            sb.append("end\n");
        }

        if (moduleName != null) {
            sb.append(String.format("%s::Test.new", moduleName));
        } else {
            sb.append("Test.new");
        }

        // A new instance is required so classes definitions doesn't clash between tests
        return Ruby.newInstance().evalScriptlet(sb.toString());
    }
}