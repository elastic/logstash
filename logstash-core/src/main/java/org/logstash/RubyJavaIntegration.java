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

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.stream.Stream;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyString;
import org.jruby.RubyModule;
import org.jruby.anno.JRubyMethod;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.java.proxies.MapJavaProxy;
import org.jruby.javasupport.Java;
import org.jruby.javasupport.JavaClass;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * The logic in this file sets up various overrides on Ruby wrapped Java collection types
 * as well as Ruby collection types that facilitate seamless interop between Java and Ruby.
 * This is mainly for usage with JrJackson json parsing in :raw mode which generates
 * Java::JavaUtil::ArrayList and Java::JavaUtil::LinkedHashMap native objects for speed.
 * these object already quacks like their Ruby equivalents Array and Hash but they will
 * not test for is_a?(Array) or is_a?(Hash) and we do not want to include tests for
 * both classes everywhere. see LogStash::JSon.
 */
public final class RubyJavaIntegration {

    private RubyJavaIntegration() {
        // Utility class
    }

    @SuppressWarnings("rawtypes")
    public static void setupRubyJavaIntegration(final Ruby ruby) {
        ruby.getArray().defineAnnotatedMethods(RubyJavaIntegration.RubyArrayOverride.class);
        ruby.getHash().defineAnnotatedMethods(RubyJavaIntegration.RubyHashOverride.class);
        Stream.of(LinkedHashMap.class, HashMap.class).forEach(cls ->
            Java.getProxyClass(ruby, cls).defineAnnotatedMethods(
                RubyJavaIntegration.RubyMapProxyOverride.class
            )
        );
        Java.getProxyClass(ruby, Map.class).defineAnnotatedMethods(
            RubyJavaIntegration.JavaMapOverride.class
        );
        Java.getProxyClass(ruby, Collection.class).defineAnnotatedMethods(
            RubyJavaIntegration.JavaCollectionOverride.class
        );
    }

    /**
     * Overrides for Ruby Array Class.
     */
    public static final class RubyArrayOverride {

        private RubyArrayOverride() {
            //Holder for RubyArray hacks only
        }

        /**
         * Enable class equivalence between Array and ArrayList so that ArrayList will work with
         * case o when Array.
         * @param context Ruby Context
         * @param rcvd Ruby class to compare against if not a Java ArrayList
         * @param obj Object to Compare Types with
         * @return True iff Ruby's `===` is fulfilled between {@code this} and {@code obj}
         */
        @JRubyMethod(name = "===", meta = true)
        public static IRubyObject opEqq(final ThreadContext context, final IRubyObject rcvd,
            final IRubyObject obj) {
            if (obj instanceof JavaProxy && Collection.class.isAssignableFrom(obj.getJavaClass())) {
                return context.tru;
            }
            return rcvd.op_eqq(context, obj);
        }
    }

    /**
     * Overrides for the Ruby Hash Class.
     */
    public static final class RubyHashOverride {

        private RubyHashOverride() {
            //Holder for RubyHash hacks only
        }

        /**
         * Enable class equivalence between Ruby's Hash and Java's Map.
         * @param context Ruby Context
         * @param rcvd Ruby class to compare against if not a Java Map
         * @param obj Object to Compare Types with
         * @return True iff Ruby's `===` is fulfilled between {@code this} and {@code obj}
         */
        @JRubyMethod(name = "===", meta = true)
        public static IRubyObject opEqq(final ThreadContext context, final IRubyObject rcvd,
            final IRubyObject obj) {
            if (obj instanceof JavaProxy && Map.class.isAssignableFrom(obj.getJavaClass())) {
                return context.tru;
            }
            return rcvd.op_eqq(context, obj);
        }
    }

    /**
     * Helper class to provide some typical Ruby methods to Java Collection class when used from Ruby
     * */
    public static final class JavaCollectionOverride {

        private static final Collection<IRubyObject> NIL_COLLECTION =
            Collections.singletonList(RubyUtil.RUBY.getNil());

        private static final Collection<IRubyObject> NULL_COLLECTION =
            Collections.singletonList(null);

        private JavaCollectionOverride() {
            // Holder for java::util::Collection hacks.
        }

        @JRubyMethod(name = "is_a?")
        public static IRubyObject isA(final ThreadContext context, final IRubyObject self,
            final IRubyObject clazz) {
            if (context.runtime.getArray().equals(clazz)) {
                return context.tru;
            }
            return ((RubyBasicObject) self).kind_of_p(context, clazz);
        }

        @JRubyMethod
        public static IRubyObject delete(final ThreadContext context, final IRubyObject self,
            final IRubyObject obj, final Block block) {
            final Object java = obj.toJava(Object.class);
            final Collection<?> unwrappedSelf = JavaUtil.unwrapIfJavaObject(self);
            if (unwrappedSelf.removeAll(Collections.singletonList(java))) {
                return obj;
            } else {
                if (block.isGiven()) {
                    return block.yield(context, obj);
                } else {
                    return context.nil;
                }
            }
        }

        @JRubyMethod
        public static IRubyObject compact(final ThreadContext context, final IRubyObject self) {
            final Collection<?> dup = new ArrayList<>(JavaUtil.unwrapIfJavaObject(self));
            removeNilAndNull(dup);
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, dup);
        }

        @JRubyMethod(name = "compact!")
        public static IRubyObject compactBang(final ThreadContext context, final IRubyObject self) {
            if (removeNilAndNull(JavaUtil.unwrapIfJavaObject(self))) {
                return self;
            } else {
                return context.nil;
            }
        }

        /**
         * Support the Ruby intersection method on Java Collection.
         * @param context Thread context
         * @param self First Ruby collection object
         * @param other Second Ruby collection object
         * @return Ruby collection containing intersection of self and other
         */
        @JRubyMethod(name = "&")
        public static IRubyObject and(final ThreadContext context, final IRubyObject self,
            final IRubyObject other) {
            final Collection<?> dup = new LinkedHashSet<>(JavaUtil.unwrapIfJavaObject(self));
            dup.retainAll(JavaUtil.unwrapIfJavaObject(other));
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, dup);
        }

        /**
         * Support the Ruby union method on Java Collection.
         * @param context Thread context
         * @param self First Ruby collection object
         * @param other Second Ruby collection object
         * @return Ruby collection containing union of self and other
         */
        @JRubyMethod(name = "|")
        public static IRubyObject or(final ThreadContext context, final IRubyObject self,
            final IRubyObject other) {
            final Collection<?> dup = new LinkedHashSet<>(JavaUtil.unwrapIfJavaObject(self));
            dup.addAll(JavaUtil.unwrapIfJavaObject(other));
            return JavaUtil.convertJavaToUsableRubyObject(context.runtime, dup);
        }

        private static boolean removeNilAndNull(final Collection<?> collection) {
            final boolean res = collection.removeAll(NIL_COLLECTION);
            return collection.removeAll(NULL_COLLECTION) || res;
        }
    }

    /**
     * Helper class to provide "is_a?" method to Java Map class when use dfrom Ruby
     * */
    public static final class JavaMapOverride {

        private JavaMapOverride() {
            // Holder for java::util::Map hacks
        }

        @JRubyMethod(name = "is_a?")
        public static IRubyObject isA(final ThreadContext context, final IRubyObject self,
            final IRubyObject clazz) {
            if (context.runtime.getHash().equals(clazz)) {
                return context.tru;
            }
            return ((RubyBasicObject) self).kind_of_p(context, clazz);
        }
    }

    /**
     * Overrides for Ruby Wrapped Java Map.
     */
    public static final class RubyMapProxyOverride {

        private RubyMapProxyOverride() {
            //Holder for Java::JavaUtil::LinkedHashMap and Java::JavaUtil::HashMap hacks only
        }

        /**
         * This is a temporary fix to solve a bug in JRuby where classes implementing the Map interface, like LinkedHashMap
         * have a bug in the has_key? method that is implemented in the Enumerable module that is somehow mixed in the Map interface.
         * this bug makes has_key? (and all its aliases) return false for a key that has a nil value.
         * Only LinkedHashMap is patched here because patching the Map interface is not working.
         * TODO find proper fix, and submit upstream
         * relevant JRuby files:
         * https://github.com/jruby/jruby/blob/master/core/src/main/ruby/jruby/java/java_ext/java.util.rb
         * https://github.com/jruby/jruby/blob/master/core/src/main/java/org/jruby/java/proxies/MapJavaProxy.java
         *
         * @param context Thread context
         * @param self Ruby map object
         * @param key Key to find
         * @return RubyBoolean of true if the map contains the key
         */
        @JRubyMethod(name = {"has_key?", "include?", "member?", "key?"})
        public static IRubyObject containsKey(final ThreadContext context, final IRubyObject self,
            final IRubyObject key) {
            return JavaUtil.<Map<?, ?>>unwrapIfJavaObject(self).containsKey(key.toJava(Object.class))
                ? context.tru : context.fals;
        }

        @JRubyMethod
        public static IRubyObject merge(final ThreadContext context, final IRubyObject self,
            final IRubyObject other) {
            IRubyObject[] other_array = { other };
            return ((MapJavaProxy) self.dup()).merge_bang(context, other_array, Block.NULL_BLOCK);
        }
    }
}
