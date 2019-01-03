package org.logstash.execution;

import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.IOException;

public interface QueueBatch {
    int filteredSize();
    @SuppressWarnings({"rawtypes"}) RubyArray to_a();
    void merge(IRubyObject event);
    void close() throws IOException;
}
