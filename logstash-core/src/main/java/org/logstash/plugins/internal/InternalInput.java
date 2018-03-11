package org.logstash.plugins.internal;

import org.logstash.ext.JrubyEventExtLibrary;

public interface InternalInput {
    boolean internalReceive(JrubyEventExtLibrary.RubyEvent event);
    boolean isRunning();
}
