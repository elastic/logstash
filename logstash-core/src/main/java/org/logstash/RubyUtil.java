package org.logstash;

import org.jruby.Ruby;

/**
 * Utilities around interaction with the {@link Ruby} runtime.
 */
public final class RubyUtil {

    /**
     * Reference to the global {@link Ruby} runtime.
     */
    public static final Ruby RUBY = setupRuby();

    private RubyUtil() {
    }

    /**
     * Sets up the global {@link Ruby} runtime and ensures the creation of the "LogStash" module
     * on it.
     * @return Global {@link Ruby} Runtime
     */
    private static Ruby setupRuby() {
        final Ruby ruby = Ruby.getGlobalRuntime();
        ruby.getOrCreateModule("LogStash");
        return ruby;
    }
}
