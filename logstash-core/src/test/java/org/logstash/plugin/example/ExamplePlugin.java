package org.logstash.plugin.example;

import org.logstash.plugin.ConstructingObjectParser;
import org.logstash.plugin.Input;
import org.logstash.plugin.Plugin;
import org.logstash.plugin.Processor;

import java.util.Collections;
import java.util.Map;

public class ExamplePlugin implements Plugin {
    public Map<String, ConstructingObjectParser<? extends Input>> getInputs() {
        return Collections.singletonMap("example", ExampleInput.EXAMPLE);
    }

    public Map<String, ConstructingObjectParser<? extends Processor>> getProcessors() {
        return Collections.singletonMap("example", ExampleProcessor.EXAMPLE_PROCESSOR);
    }

}
