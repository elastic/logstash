package org.logstash.execution;

import co.elastic.logstash.api.v0.Input;

import java.util.ArrayList;
import java.util.Collection;

/**
 * Provides a single point of control for a set of Java inputs.
 */
public class InputsController {

    private final Collection<Input> inputs;

    public InputsController(final Collection<Input> inputs) {
        this.inputs = inputs;
    }

    public void startInputs(final JavaBasePipelineExt provider) {
        int inputCounter = 0;
        for (Input input : inputs) {
            String pluginName = input.getName();
            Thread t = new Thread(() -> input.start(provider.getQueueWriter(pluginName)));
            t.setName("input_" + (inputCounter++) + "_" + pluginName);
            t.start();
        }
    }

    public void stopInputs() {
        for (Input input : inputs) {
            input.stop();
        }
    }

    public void awaitStop() {
        // trivial implementation
        for (Input input : inputs) {
            try {
                input.awaitStop();
            } catch (InterruptedException e) {
                // do nothing
            }
        }
    }
}
