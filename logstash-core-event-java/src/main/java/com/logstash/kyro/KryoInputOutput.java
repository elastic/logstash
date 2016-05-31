package com.logstash.kyro;

import com.esotericsoftware.kryo.io.Input;
import com.esotericsoftware.kryo.io.Output;

public class KryoInputOutput {
    private Input input;
    private Output output;

    public KryoInputOutput(Input input, Output output) {
        this.input = input;
        this.output = output;
    }

    public Input getInput() {
        return input;
    }

    public Output getOutput() {
        return output;
    }
}
