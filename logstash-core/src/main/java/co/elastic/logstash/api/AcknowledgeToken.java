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

/**
 * Interface for the acknowledgeTokens added to Events if a
 * acknoledgement of processing is desired for the event.
 * Concrete implementations should be threadsafe and should be created
 * by {@link AcknowledgeTokenFactory} instances managed by {@link AcknowledgeBus}
 * and not directly by plugins themselves.
 */
public interface AcknowledgeToken {

    /**
     * Returns unique pluginId that issued acknowledgeToken
     *
     * @return Returns pluginId that issued acknowledgeToken
     */
    String getPluginId();

    /**
     * Returns acknowledgeId that identifies the event(s) for the plugin
     * wanting to receive acknowlegement. The combination acknowledgeId
     * and pluginId must be unique.
     *
     * @return Returns pluginId that issued acknowledgeToken
     */
    String getAcknowledgeId();

}
