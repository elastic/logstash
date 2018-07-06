package org.logstash.ext;

import org.assertj.core.api.Assertions;
import org.jruby.RubyString;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.Event;
import org.logstash.RubyUtil;

public class JrubyEventExtLibraryTest {

    @Test
    public void correctlyHandlesNonAsciiKeys() {
        final RubyString key = rubyString("[テストフィールド]");
        final RubyString value = rubyString("someValue");
        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final JrubyEventExtLibrary.RubyEvent event =
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime, new Event());
        event.ruby_set_field(context, key, value);
        Assertions.assertThat(event.ruby_to_json(context, new IRubyObject[0]).asJavaString())
            .contains("\"テストフィールド\":\"someValue\"");
        }

    private static RubyString rubyString(final String java) {
        return RubyUtil.RUBY.newString(java);
    }
}
