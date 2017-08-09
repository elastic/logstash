package org.logstash.config.ir.compiler;

import org.jruby.RubyArray;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

public final class RubyIntegration {

    public interface Plugin {
        void register();
    }

    public interface Filter extends RubyIntegration.Plugin {

        RubyArray multiFilter(RubyArray events);

        boolean hasFlush();

        boolean periodicFlush();
    }

    public interface Output extends RubyIntegration.Plugin {
        void multiReceive(RubyArray events);
    }

    public interface Pipeline {

        IRubyObject buildInput(RubyString name, IRubyObject args);

        RubyIntegration.Output buildOutput(RubyString name, IRubyObject args);

        RubyIntegration.Filter buildFilter(RubyString name, IRubyObject args);
    }
}
