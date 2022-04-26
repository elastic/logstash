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

/**
 * Represents the in endpoint of a pipeline to pipeline communication.
 * */
public interface PipelineInput {

    enum ReceiveStatus {CLOSING, COMPLETED, FAIL}

    final class ReceiveResponse {
        private final ReceiveStatus status;
        private final Integer sequencePosition;
        private final Throwable cause;

        static ReceiveResponse closing() {
            return new ReceiveResponse(ReceiveStatus.CLOSING);
        }

        static ReceiveResponse completed() {
            return new ReceiveResponse(ReceiveStatus.COMPLETED);
        }

        static ReceiveResponse failedAt(int sequencePosition, Throwable cause) {
            return new ReceiveResponse(ReceiveStatus.FAIL, sequencePosition, cause);
        }

        private ReceiveResponse(ReceiveStatus status) {
            this(status, null);
        }

        private ReceiveResponse(ReceiveStatus status, Integer sequencePosition) {
            this(status, sequencePosition, null);
        }

        private ReceiveResponse(ReceiveStatus status, Integer sequencePosition, Throwable cause) {
            this.status = status;
            this.sequencePosition = sequencePosition;
            this.cause = cause;
        }

        public ReceiveStatus getStatus() {
            return status;
        }

        public Integer getSequencePosition() {
            return sequencePosition;
        }

        public boolean wasSuccess() {
            return status == PipelineInput.ReceiveStatus.COMPLETED;
        }

        public String getCauseMessage() {
            return cause != null ? cause.getMessage() : "UNDEFINED ERROR";
        }
    }

    /**
     * Accepts an event. It might be rejected if the input is stopping.
     *
     * @param events a collection of events
     * @return response instance which contains the status of the execution, if events were successfully received
     *      or reached an error or the input was closing.
     */
    ReceiveResponse internalReceive(Stream<JrubyEventExtLibrary.RubyEvent> events);

    /**
     * @return true if the input is running
     */
    boolean isRunning();
}
