package org.logstash.ext;

import org.junit.Test;
import org.logstash.RubyUtil;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.not;
import static org.hamcrest.MatcherAssert.assertThat;

public final class TimestampTest {

    @Test
    public void testClone() {
        assertThat(
            RubyUtil.RUBY.executeScript("LogStash::Timestamp.now.clone.to_java", ""),
            not(is(RubyUtil.RUBY.getNil()))
        );
        assertThat(
            RubyUtil.RUBY.executeScript("LogStash::Timestamp.now.dup.to_java", ""),
            not(is(RubyUtil.RUBY.getNil()))
        );
    }
}
