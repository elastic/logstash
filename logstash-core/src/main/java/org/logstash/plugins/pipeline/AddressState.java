/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.plugins.pipeline;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Represents the state of an internal address.
 */
public class AddressState {

    private final Set<PipelineOutput> outputs = ConcurrentHashMap.newKeySet();
    private volatile PipelineInput input = null;

    /**
     * Add the given output and ensure associated input's receivers are updated
     * @param output output to be added
     * @return true if the output was not already added
     */
    public boolean addOutput(PipelineOutput output) {
        return outputs.add(output);
    }

    public boolean removeOutput(PipelineOutput output) {
        return outputs.remove(output);
    }

    public PipelineInput getInput() {
        return input;
    }

    /**
     * Assigns an input to listen on this address. Will return false if another input is already listening.
     * @param newInput input to assign as listener
     * @return true if successful, false if another input is listening
     */
    public synchronized boolean assignInputIfMissing(PipelineInput newInput) {
        // We aren't changing anything
        if (input == null) {
            input = newInput;
            return true;
        } else {
            return input == newInput;
        }
    }

    /**
     * Unsubscribes the given input from this address
     * @param unsubscribingInput input to unsubscribe from this address
     * @return true if this input was listening, false otherwise
     */
    public synchronized boolean unassignInput(PipelineInput unsubscribingInput) {
        if (input != unsubscribingInput) return false;

        input = null;
        return true;
    }

    public boolean isRunning() {
        return input != null && input.isRunning();
    }

    public boolean isEmpty() {
        return (input == null) && outputs.isEmpty();
    }

    // Just for tests
    boolean hasOutput(PipelineOutput output) {
        return outputs.contains(output);
    }

    public Set<PipelineOutput> getOutputs() {
        return outputs;
    }
}
