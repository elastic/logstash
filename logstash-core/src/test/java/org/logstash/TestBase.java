package org.logstash;

import org.logstash.ext.JrubyTimestampExtLibrary;
import org.jruby.CompatVersion;
import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.junit.Before;

public abstract class TestBase {
    private static boolean setupDone = false;
    public static Ruby ruby;

    @Before
    public void setUp() throws Exception {
        if (setupDone) return;

        RubyInstanceConfig config = new RubyInstanceConfig();
        ruby = Ruby.newInstance(config);
        RubyBigDecimal.createBigDecimal(ruby); // we need to do 'require "bigdecimal"'
        JrubyTimestampExtLibrary.createTimestamp(ruby);
        setupDone = true;
    }
}
