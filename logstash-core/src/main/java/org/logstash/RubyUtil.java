package org.logstash;

import org.jruby.NativeException;
import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.exceptions.RaiseException;

/**
 * Utilities around interaction with the {@link Ruby} runtime.
 */
public final class RubyUtil {

    /**
     * Reference to the global {@link Ruby} runtime.
     */
    public static final Ruby RUBY;

    /**
     * Logstash Ruby Module.
     */
    public static final RubyModule LOGSTASH_MODULE;

    static {
        RUBY = Ruby.getGlobalRuntime();
        LOGSTASH_MODULE = RUBY.getOrCreateModule("LogStash");
    }

    private RubyUtil() {
    }

    /**
     * Wraps a Java exception in a JRuby IOError NativeException.
     * This preserves the Java stacktrace and bubble up as a Ruby IOError
     * @param runtime the Ruby runtime context
     * @param e the Java exception to wrap
     * @return RaiseException the wrapped IOError
     */
    public static RaiseException newRubyIOError(Ruby runtime, Throwable e) {
        // will preserve Java stacktrace & bubble up as a Ruby IOError
        return new RaiseException(e, new NativeException(runtime, runtime.getIOError(), e));
    }
}
