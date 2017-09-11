package org.logstash.plugin;

import java.util.Map;

public interface Plugin {
    // register hooks
    // additional settings

    default Map<String, ConstructingObjectParser<? extends Input>> getInputs() {
        return null;
    }

    default Map<String, ConstructingObjectParser<? extends Processor>> getProcessors() {
        return null;
    }

    default Map<String, ConstructingObjectParser<? extends Output>> getOutputs() {
        return null;
    }
}
