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

import java.time.Instant;
import java.time.ZonedDateTime;
import java.util.concurrent.TimeUnit;
import org.assertj.core.api.Assertions;
import org.jruby.RubyString;
import org.jruby.RubyTime;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyTestBase;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;

/**
 * Tests for {@link JrubyTimestampExtLibrary}.
 */
public final class JrubyTimestampExtLibraryTest extends RubyTestBase {

    @Test
    public void testConstructorNew() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyTimestampExtLibrary.RubyTimestamp t =
            newRubyTimestamp(context, new IRubyObject[0]);
        final long now =
            TimeUnit.SECONDS.convert(System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        Assertions.assertThat(t.ruby_time(context).to_i().getLongValue())
            .isBetween(now - 1L, now + 2L);
    }

    @Test
    public void testConstructorNow() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyTimestampExtLibrary.RubyTimestamp t =
            JrubyTimestampExtLibrary.RubyTimestamp.ruby_now(context, RubyUtil.RUBY_TIMESTAMP_CLASS);
        final long now =
            TimeUnit.SECONDS.convert(System.currentTimeMillis(), TimeUnit.MILLISECONDS);
        Assertions.assertThat(t.ruby_time(context).to_i().getLongValue())
            .isBetween(now - 1L, now + 2L);
    }

    @Test
    public void testConstructFromRubyDateTime() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject now = RubyTime.newTime(context.runtime, System.currentTimeMillis());
        final JrubyTimestampExtLibrary.RubyTimestamp t = newRubyTimestamp(context, new IRubyObject[]{now});
        Assertions.assertThat(
            Math.abs(
                t.ruby_time(context).to_f().getDoubleValue() - now.convertToFloat().getDoubleValue()
            )
        ).isLessThan(0.000999999);
        final IRubyObject nowToI = now.callMethod(context, "to_i");
        Assertions.assertThat(JrubyTimestampExtLibrary.RubyTimestamp.ruby_at(
            context, RubyUtil.RUBY_TIMESTAMP_CLASS, new IRubyObject[]{nowToI}
        ).ruby_to_i(context)).isEqualTo(nowToI);
    }

    @Test
    public void testConsistentEql() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final IRubyObject[] itsXmas =
            {context.runtime.evalScriptlet("Time.utc(2015, 12, 25, 0, 0, 0)")};
        final IRubyObject left = newRubyTimestamp(context, itsXmas);
        final IRubyObject right = newRubyTimestamp(context, itsXmas);
        Assertions.assertThat(left.callMethod(context, "eql?", right).isTrue()).isTrue();
        Assertions.assertThat(left.callMethod(context, "==", right).isTrue()).isTrue();
    }

    @Test(expected = RaiseException.class)
    public void testRaiseOnInvalidFormat() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        newRubyTimestamp(context, new IRubyObject[]{context.runtime.newString("foobar")});
    }

    @Test
    public void testCompareAnyType() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        Assertions.assertThat(
            newRubyTimestamp(context, new IRubyObject[0]).eql(
                context, context.runtime.newString("-")
            ).isTrue()
        ).isFalse();
    }

    @Test
    public void testCoerceInstanceOfRubyTimestamp() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyTimestampExtLibrary.RubyTimestamp source = JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(context.runtime, Timestamp.now());

        final IRubyObject coerced = JrubyTimestampExtLibrary.RubyTimestamp.ruby_coerce(context, RubyUtil.RUBY_TIMESTAMP_CLASS, source);

        Assertions.assertThat(coerced)
                .isNotNull()
                .isInstanceOfSatisfying(JrubyTimestampExtLibrary.RubyTimestamp.class, koerced -> {
                   Assertions.assertThat(koerced).isEqualTo(source);
                });
    }

    @Test
    public void testCoerceInstanceOfRubyTime() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final RubyTime rubyTime = RubyTime.newTimeFromNanoseconds(context.runtime, 1L);

        final IRubyObject coerced = JrubyTimestampExtLibrary.RubyTimestamp.ruby_coerce(context, RubyUtil.RUBY_TIMESTAMP_CLASS, rubyTime);

        Assertions.assertThat(coerced)
                .isNotNull()
                .isInstanceOfSatisfying(JrubyTimestampExtLibrary.RubyTimestamp.class, koerced -> {
                    Assertions.assertThat(koerced.getTimestamp().toInstant()).isEqualTo(rubyTime.toInstant());
                });
    }

    @Test
    public void testCoerceInstanceOfRubyString() {
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final RubyString timestamp = RubyString.newString(context.runtime, "2021-08-30T08:04:57.918273645-08:00");
        final Instant instant = ZonedDateTime.parse(timestamp).toInstant();
        final JrubyTimestampExtLibrary.RubyTimestamp source = newRubyTimestamp(context, new IRubyObject[]{ timestamp });

        final IRubyObject coerced = JrubyTimestampExtLibrary.RubyTimestamp.ruby_coerce(context, RubyUtil.RUBY_TIMESTAMP_CLASS, source);

        Assertions.assertThat(coerced)
                .isNotNull()
                .isInstanceOfSatisfying(JrubyTimestampExtLibrary.RubyTimestamp.class, koerced -> Assertions.assertThat(koerced.getTimestamp().toInstant()).isEqualTo(instant));

    }

    private static JrubyTimestampExtLibrary.RubyTimestamp newRubyTimestamp(
        final ThreadContext context, final IRubyObject[] args) {
        return new JrubyTimestampExtLibrary.RubyTimestamp(
            context.runtime, RubyUtil.RUBY_TIMESTAMP_CLASS
        ).initialize(context, args);
    }
}
