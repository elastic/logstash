package org.logstash.config.ir.compiler;

import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * This class holds interfaces implemented by Ruby concrete classes.
 */
public final class RubyIntegration {

    private RubyIntegration() {
        //Utility Class.
    }

    /**
     * A Ruby Plugin.
     */
    public interface Plugin {
        void register();
    }

    /**
     * A Ruby Filter. Currently, this interface is implemented only by the Ruby class
     * {@code FilterDelegator}.
     */
    public interface Filter extends RubyIntegration.Plugin {

        /**
         * Returns the underlying {@link IRubyObject} for this filter instance.
         * @return Underlying {@link IRubyObject}
         */
        IRubyObject toRuby();

        /**
         * Checks if this filter has a flush method.
         * @return True iff this filter has a flush method
         */
        boolean hasFlush();

        /**
         * Checks if this filter does periodic flushing.
         * @return True iff this filter uses periodic flushing
         */
        boolean periodicFlush();
    }

    /**
     * Plugin Factory that instantiates Ruby plugins and is implemented in Ruby.
     */
    public interface PluginFactory {

        IRubyObject buildInput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        IRubyObject buildOutput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildFilter(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildCodec(RubyString name, IRubyObject args);
    }
}
