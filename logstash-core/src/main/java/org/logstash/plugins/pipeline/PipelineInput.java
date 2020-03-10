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

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.stream.Stream;

public interface PipelineInput {
    /**
     * Accepts an event. It might be rejected if the input is stopping.
     *
     * @param events a collection of events
     * @return true if the event was successfully received
     */
    boolean internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events);

    /**
     * @return true if the input is running
     */
    boolean isRunning();
}
