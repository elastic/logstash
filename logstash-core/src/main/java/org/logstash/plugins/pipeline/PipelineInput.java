package org.logstash.plugins.pipeline;

import org.logstash.ext.JrubyEventExtLibrary;

public interface PipelineInput {
    boolean internalReceive(JrubyEventExtLibrary.RubyEvent event);
    boolean isRunning();
}
