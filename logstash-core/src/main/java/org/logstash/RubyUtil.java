package org.logstash;

import org.jruby.NativeException;
import org.jruby.Ruby;
import org.jruby.exceptions.RaiseException;

/**
 * Utilities around interaction with the {@link Ruby} runtime.
 */
public final class RubyUtil {

    /**
     * Name of the Logstash JRuby module we register.
     */
    public static final String LS_MODULE_NAME = "LogStash";

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
        ruby.getOrCreateModule(LS_MODULE_NAME);
        return ruby;
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
