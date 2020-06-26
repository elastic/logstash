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

public interface AcknowledgablePlugin extends Plugin {
    /**
     * Accepts an acknowledgeId which was put into the event at creation by the plugin.
     *
     * @param acknowledgeId acknowledgeId added to event on creation by the plugin
     * @return true if the event was successfully received
     */
    boolean acknowledge(final String acknowledgeId);

    /**
     * Accepts an acknowledgeId which was put into the event at creation by the plugin.
     * Is called when event is a clone event is put onto the acknowledge bus, like when
     * it is passed to other pipeline in the case of multi pipeline communication.
     *
     * @param acknowledgeId acknowledgeId added to event on creation by the plugin
     * @return true if the event was successfully received
     */
    boolean notifyCloned(final String acknowledgeId);

}
