package org.logstash.ext;

import java.util.concurrent.TimeUnit;
import org.assertj.core.api.Assertions;
import org.jruby.exceptions.RaiseException;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;

/**
 * Tests for {@link JrubyTimestampExtLibrary}.
 */
public final class JrubyTimestampExtLibraryTest {

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
        final IRubyObject now =
            context.runtime.evalScriptlet("require 'date'\nDateTime.now.to_time.utc");
        final JrubyTimestampExtLibrary.RubyTimestamp t =
            newRubyTimestamp(context, new IRubyObject[]{now});
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

    private static JrubyTimestampExtLibrary.RubyTimestamp newRubyTimestamp(
        final ThreadContext context, final IRubyObject[] args) {
        return new JrubyTimestampExtLibrary.RubyTimestamp(
            context.runtime, RubyUtil.RUBY_TIMESTAMP_CLASS
        ).initialize(context, args);
    }
}
