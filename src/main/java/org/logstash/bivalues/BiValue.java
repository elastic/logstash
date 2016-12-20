package org.logstash.bivalues;

import org.jruby.Ruby;
import org.jruby.runtime.builtin.IRubyObject;

public interface BiValue<R extends IRubyObject, J> {
    IRubyObject rubyValue(Ruby runtime);

    J javaValue();

    R rubyValueUnconverted();

    boolean hasRubyValue();

    boolean hasJavaValue();
}


