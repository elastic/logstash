package org.logstash;

import org.jruby.Ruby;
import org.jruby.ext.bigdecimal.RubyBigDecimal;
import org.junit.Before;
import org.logstash.ext.JrubyTimestampExtLibrary;

public abstract class TestBase {
    private static boolean setupDone = false;
    public static final Ruby ruby = Ruby.getGlobalRuntime();

    @Before
    public void setUp() throws Exception {
        if (setupDone) return;
        RubyBigDecimal.createBigDecimal(ruby); // we need to do 'require "bigdecimal"'
        JrubyTimestampExtLibrary.createTimestamp(ruby);
        setupDone = true;
    }
}
