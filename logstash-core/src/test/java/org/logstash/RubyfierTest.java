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

import org.jruby.RubyArray;
import org.jruby.RubyBignum;
import org.jruby.RubyFixnum;
import org.jruby.RubyFloat;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;

public class RubyfierTest extends RubyTestBase {

    @Test
    public void testDeepWithString() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, "foo");
        assertEquals(RubyString.class, result.getClass());
        assertEquals("foo", result.toString());
    }

    @Test
    public void testDeepMapWithString() throws Exception {
        Map<String, String> data = new HashMap<>();
        data.put("foo", "bar");
        RubyHash rubyHash = (RubyHash) Rubyfier.deep(RubyUtil.RUBY, data);

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, "foo"));

        assertEquals(RubyString.class, result.getClass());
        assertEquals("bar", result.toString());
    }

    @Test
    public void testDeepListWithString() throws Exception {
        List<String> data = new ArrayList<>();
        data.add("foo");

        @SuppressWarnings("rawtypes")
        RubyArray rubyArray = (RubyArray)Rubyfier.deep(RubyUtil.RUBY, data);

        // toJavaArray does not newFromRubyArray inner elements to Java types \o/
        assertEquals(RubyString.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals("foo", rubyArray.toJavaArray()[0].toString());
    }

    @Test
    public void testDeepWithInteger() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, 1);
        assertEquals(RubyFixnum.class, result.getClass());
        assertEquals(1L, ((RubyFixnum)result).getLongValue());
    }

    @Test
    public void testDeepMapWithInteger() throws Exception {
        Map<String, Integer> data = new HashMap<>();
        data.put("foo", 1);
        RubyHash rubyHash = (RubyHash)Rubyfier.deep(RubyUtil.RUBY, data);

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, "foo"));

        assertEquals(RubyFixnum.class, result.getClass());
        assertEquals(1L, ((RubyFixnum)result).getLongValue());
    }

    @Test
    public void testDeepListWithInteger() throws Exception {
        List<Integer> data = new ArrayList<>();
        data.add(1);

        @SuppressWarnings("rawtypes")
        RubyArray rubyArray = (RubyArray)Rubyfier.deep(RubyUtil.RUBY, data);

        // toJavaArray does not newFromRubyArray inner elements to Java types \o/
        assertEquals(RubyFixnum.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1L, ((RubyFixnum)rubyArray.toJavaArray()[0]).getLongValue());
    }

    @Test
    public void testDeepWithFloat() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, 1.0F);
        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithFloat() throws Exception {
        Map<String, Float> data = new HashMap<>();
        data.put("foo", 1.0F);
        RubyHash rubyHash = (RubyHash)Rubyfier.deep(RubyUtil.RUBY, data);

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, "foo"));

        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithFloat() throws Exception {
        List<Float> data = new ArrayList<>();
        data.add(1.0F);

        @SuppressWarnings("rawtypes")
        RubyArray rubyArray = (RubyArray)Rubyfier.deep(RubyUtil.RUBY, data);

        // toJavaArray does not newFromRubyArray inner elements to Java types \o/
        assertEquals(RubyFloat.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyFloat)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }

    @Test
    public void testDeepWithDouble() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, 1.0D);
        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithDouble() throws Exception {
        Map<String, Double> data = new HashMap<>();
        data.put("foo", 1.0D);
        RubyHash rubyHash = (RubyHash)Rubyfier.deep(RubyUtil.RUBY, data);

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, "foo"));

        assertEquals(RubyFloat.class, result.getClass());
        assertEquals(1.0D, ((RubyFloat)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithDouble() throws Exception {
        List<Double> data = new ArrayList<>();
        data.add(1.0D);

        @SuppressWarnings("rawtypes")
        RubyArray rubyArray = (RubyArray)Rubyfier.deep(RubyUtil.RUBY, data);

        // toJavaArray does not newFromRubyArray inner elements to Java types \o/
        assertEquals(RubyFloat.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyFloat)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }

    @Test
    public void testDeepWithBigDecimal() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, new BigDecimal(1));
        assertEquals(RubyBigDecimal.class, result.getClass());
        assertEquals(1.0D, ((RubyBigDecimal)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepMapWithBigDecimal() throws Exception {
        Map<String, BigDecimal> data = new HashMap<>();
        data.put("foo", new BigDecimal(1));

        RubyHash rubyHash = (RubyHash)Rubyfier.deep(RubyUtil.RUBY, data);

        // Hack to be able to retrieve the original, unconverted Ruby object from Map
        // it seems the only method providing this is internalGet but it is declared protected.
        // I know this is bad practice but I think this is practically acceptable.
        Method internalGet = RubyHash.class.getDeclaredMethod("internalGet", IRubyObject.class);
        internalGet.setAccessible(true);
        Object result = internalGet.invoke(rubyHash, JavaUtil.convertJavaToUsableRubyObject(RubyUtil.RUBY, "foo"));

        assertEquals(RubyBigDecimal.class, result.getClass());
        assertEquals(1.0D, ((RubyBigDecimal)result).getDoubleValue(), 0);
    }

    @Test
    public void testDeepListWithBigDecimal() throws Exception {
        List<BigDecimal> data = new ArrayList<>();
        data.add(new BigDecimal(1));

        @SuppressWarnings("rawtypes")
        RubyArray rubyArray = (RubyArray)Rubyfier.deep(RubyUtil.RUBY, data);

        // toJavaArray does not newFromRubyArray inner elements to Java types \o/
        assertEquals(RubyBigDecimal.class, rubyArray.toJavaArray()[0].getClass());
        assertEquals(1.0D, ((RubyBigDecimal)rubyArray.toJavaArray()[0]).getDoubleValue(), 0);
    }


    @Test
    public void testDeepWithBigInteger() {
        Object result = Rubyfier.deep(RubyUtil.RUBY, new BigInteger("1"));
        assertEquals(RubyBignum.class, result.getClass());
        assertEquals(1L, ((RubyBignum)result).getLongValue());
    }

}
