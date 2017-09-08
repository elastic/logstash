package org.logstash.plugin;

public interface Plugin {
    // register hooks
    // additional settings

    default ConstructingObjectParser<? extends Input> getInputs() {
        return null;
    }

    default ConstructingObjectParser<? extends Processor> getProcessors() {
        return null;
    }

    default ConstructingObjectParser<? extends Output> getOutputs() {
        return null;
    }
}
