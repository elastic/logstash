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
package org.logstash.health;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

public class HealthObserver {

    private static final Logger LOGGER = LogManager.getLogger();

    static final String FORCE_API_STATUS_PROPERTY = "logstash.forceApiStatus";

    private final MultiIndicator rootIndicator = new MultiIndicator();
    private final MultiIndicator pipelinesIndicator = new MultiIndicator();

    public HealthObserver() {
        this.rootIndicator.attachIndicator("pipelines", this.pipelinesIndicator);
    }

    public final Status getStatus() {
        // Short-term escape-hatch
        final String forceApiStatus = System.getProperty(FORCE_API_STATUS_PROPERTY);
        if (forceApiStatus != null) {
            if (forceApiStatus.equals("green")) {
                return Status.GREEN;
            } else {
                LOGGER.warn("Unsupported `logstash.forceApiStatus`: {} (health report status will be propagated)", forceApiStatus);
            }
        }
        return getReport().getStatus();
    }

    public MultiIndicator getIndicator() {
        return this.rootIndicator;
    }

    public ApiHealthReport getReport() {
        return new ApiHealthReport(this.rootIndicator.report());
    }

    public void attachPipelineIndicator(final String pipelineId, final PipelineIndicator.PipelineDetailsProvider detailsProvider) {
        try {
            this.pipelinesIndicator.attachIndicator(pipelineId, PipelineIndicator.forPipeline(pipelineId, detailsProvider));
            LOGGER.debug(String.format("attached pipeline indicator [%s]", pipelineId));
        } catch (final Exception e) {
            LOGGER.warn(String.format("failed to attach pipeline indicator [%s]", pipelineId), e);
        }
    }

    public void detachPipelineIndicator(final String pipelineId) {
        try {
            this.pipelinesIndicator.detachIndicator(pipelineId, null);
            LOGGER.debug(String.format("detached pipeline indicator [%s]", pipelineId));
        } catch (final Exception e) {
            LOGGER.warn(String.format("failed to detach pipeline indicator [%s]", pipelineId), e);
        }
    }
}
