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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.joda.time.DateTime;
import org.jruby.RubyClass;
import org.jruby.RubyMatchData;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.java.proxies.ArrayJavaProxy;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.Java;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.ExpectedException;
import org.logstash.ext.JrubyTimestampExtLibrary;

import static junit.framework.TestCase.assertEquals;

public class ValuefierTest extends RubyTestBase {

    @Test
    public void testMapJavaProxy() {
        Map<IRubyObject, IRubyObject> map = new HashMap<>();
        map.put(RubyString.newString(RubyUtil.RUBY, "foo"), RubyString.newString(RubyUtil.RUBY, "bar"));
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(RubyUtil.RUBY, HashMap.class);
        MapJavaProxy mjp = new MapJavaProxy(RubyUtil.RUBY, proxyClass);
        mjp.setObject(map);

        Object result = Valuefier.convert(mjp);
        assertEquals(ConvertedMap.class, result.getClass());
        ConvertedMap m = (ConvertedMap) result;
    }

    @Test
    public void testArrayJavaProxy() {
        IRubyObject[] array = new IRubyObject[]{RubyString.newString(RubyUtil.RUBY, "foo")};
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(RubyUtil.RUBY, String[].class);
        ArrayJavaProxy ajp = new ArrayJavaProxy(RubyUtil.RUBY, proxyClass, array);

        Object result = Valuefier.convert(ajp);
        assertEquals(ConvertedList.class, result.getClass());
        List<Object> a = (ConvertedList) result;
    }

    @Test
    public void testConcreteJavaProxy() {
        List<IRubyObject> array = new ArrayList<>();
        array.add(RubyString.newString(RubyUtil.RUBY, "foo"));
        RubyClass proxyClass = (RubyClass) Java.getProxyClass(RubyUtil.RUBY, ArrayList.class);
        ConcreteJavaProxy cjp = new ConcreteJavaProxy(RubyUtil.RUBY, proxyClass, array);
        Object result = Valuefier.convert(cjp);
        assertEquals(ConvertedList.class, result.getClass());
        List<Object> a = (ConvertedList) result;
    }

    @Test
    public void testRubyTime() {
        RubyTime ro = RubyTime.newTime(RubyUtil.RUBY, DateTime.now());
        Object result = Valuefier.convert(ro);
        assertEquals(JrubyTimestampExtLibrary.RubyTimestamp.class, result.getClass());
    }

    @Test
    public void testJodaDateTIme() {
        DateTime jo = DateTime.now();
        Object result = Valuefier.convert(jo);

        assertEquals(JrubyTimestampExtLibrary.RubyTimestamp.class, result.getClass());
    }

    @Test
    public void testLocalDate() {
        LocalDate ld = LocalDate.now();
        Object result = Valuefier.convert(ld);

        assertEquals(JrubyTimestampExtLibrary.RubyTimestamp.class, result.getClass());
    }

    @Test
    public void testLocalDateTime() {
        LocalDateTime ldt = LocalDateTime.now();
        Object result = Valuefier.convert(ldt);

        assertEquals(JrubyTimestampExtLibrary.RubyTimestamp.class, result.getClass());
    }

    @Test
    public void testZonedDateTime() {
        ZonedDateTime zdt = ZonedDateTime.of(2022,4,4,5,6,13,123, ZoneId.of("Europe/London"));
        JrubyTimestampExtLibrary.RubyTimestamp result = (JrubyTimestampExtLibrary.RubyTimestamp) Valuefier.convert(zdt);
        assertEquals(zdt.toInstant().toEpochMilli(), result.getTimestamp().toEpochMilli());
    }

    @Rule
    public ExpectedException exception = ExpectedException.none();

    @Test
    public void testUnhandledObject() {
        RubyMatchData md = new RubyMatchData(RubyUtil.RUBY);
        exception.expect(MissingConverterException.class);
        exception.expectMessage("Missing Converter handling for full class name=org.jruby.RubyMatchData, simple name=RubyMatchData");
        Valuefier.convert(md);
    }

    @Test
    public void scratch() {
        String[] parts = "foo/1_4".split("\\W|_");
        int ord = Integer.valueOf(parts[1]);
        assertEquals(ord, 1);
    }
}
