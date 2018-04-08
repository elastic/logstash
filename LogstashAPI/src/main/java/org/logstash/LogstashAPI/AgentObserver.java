package org.logstash.LogstashAPI;

import org.pf4j.ExtensionPoint;

public interface AgentObserver extends ExtensionPoint {
    void onStart();
    void onShutdown();
}
