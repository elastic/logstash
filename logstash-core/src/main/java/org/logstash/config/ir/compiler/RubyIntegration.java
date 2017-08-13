package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.ext.JrubyEventExtLibrary;

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
     * A Ruby Filter.
     */
    public interface Filter extends RubyIntegration.Plugin {

        RubyArray multiFilter(RubyArray events);

        boolean hasFlush();

        boolean periodicFlush();
    }

    /**
     * A Ruby Output.
     */
    public interface Output extends RubyIntegration.Plugin {
        void multiReceive(RubyArray events);
    }

    /**
     * The Main Ruby Pipeline Class.
     */
    public interface Pipeline {

        IRubyObject buildInput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Output buildOutput(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildFilter(RubyString name, RubyInteger line, RubyInteger column,
            IRubyObject args);

        RubyIntegration.Filter buildCodec(RubyString name, IRubyObject args);
    }

    public interface Batch {

        Collection<JrubyEventExtLibrary.RubyEvent> collect();
    }
}
