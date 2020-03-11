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


package co.elastic.logstash.api;

import java.util.Map;
import java.util.function.Consumer;

/**
 * Logstash Java input interface. Inputs produce events that flow through the Logstash event pipeline. Inputs are
 * flexible and may produce events through many different mechanisms including:
 *
 * <ul>
 *     <li>a pull mechanism such as periodic queries of external database</li>
 *     <li>a push mechanism such as events sent from clients to a local network port</li>
 *     <li>a timed computation such as a heartbeat</li>
 * </ul>
 *
 * or any other mechanism that produces a useful stream of events. Event streams may be either finite or infinite.
 * Logstash will run as long as any one of its inputs is still producing events.
 */
public interface Input extends Plugin {

    /**
     * Start the input and begin pushing events to the supplied {@link Consumer} instance. If the input produces
     * an infinite stream of events, this method should loop until a {@link #stop()} request is made. If the
     * input produces a finite stream of events, this method should terminate when the last event in the stream
     * is produced.
     * @param writer Consumer to which events should be pushed
     */
    void start(Consumer<Map<String, Object>> writer);

    /**
     * Notifies the input to stop producing events. Inputs stop both asynchronously and cooperatively. Use the
     * {@link #awaitStop()} method to block until the input has completed the stop process.
     */
    void stop();

    /**
     * Blocks until the input has stopped producing events. Note that this method should <b>not</b> signal the
     * input to stop as the {@link #stop()} method does.
     * @throws InterruptedException On Interrupt
     */
    void awaitStop() throws InterruptedException;

}
