package org.logstash.LogstashAPI;

import org.pf4j.ExtensionPoint;

public interface PipelineObserver extends ExtensionPoint {
    void onStart(String id);
    void onStop(String id);
}
