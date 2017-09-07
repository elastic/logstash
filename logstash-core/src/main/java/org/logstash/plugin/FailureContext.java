package org.logstash.plugin;

import java.util.Map;

public interface FailureContext {
    String getMessage();

    // Do we need a map of the context? Or do we want to rely on just a complex string as the message?
    Map<String, Object> getContext();
}
