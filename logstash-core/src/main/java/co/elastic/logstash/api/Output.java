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

import java.util.Collection;

/**
 * Logstash Java output interface. Outputs may send events to local sinks such as the console or a file or to remote
 * systems such as Elasticsearch or other external systems.
 */
public interface Output extends Plugin {

    /**
     * Outputs Collection of {@link Event}.
     * @param events Events to be sent through the output.
     */
    void output(Collection<Event> events);

    /**
     * Notifies the output to stop sending events. Outputs with connections to external systems or other resources
     * requiring cleanup should perform those tasks upon a stop notification. Outputs stop both asynchronously and
     * cooperatively. Use the {@link #awaitStop()} method to block until an output has completed the stop process.
     */
    void stop();

    /**
     * Blocks until the output has stopped sending events. Note that this method should <b>not</b> signal the
     * output to stop as the {@link #stop()} method does.
     * @throws InterruptedException On Interrupt
     */
    void awaitStop() throws InterruptedException;

}
