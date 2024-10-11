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

import java.util.Objects;
import java.util.function.UnaryOperator;

public interface Probe<OBSERVATION extends ProbeIndicator.Observation> {
    Analysis analyze(OBSERVATION observation);

    final class Analysis {
        public final Status status;
        public final Diagnosis diagnosis;
        public final Impact impact;

        Analysis(final Builder builder) {
            this.status = builder.status;
            this.diagnosis = builder.diagnosis;
            this.impact = builder.impact;
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private final Status status;
            private final Diagnosis diagnosis;
            private final Impact impact;

            public Builder() {
                this(Status.GREEN, null, null);
            }

            public Builder(final Status status,
                           final Diagnosis diagnosis,
                           final Impact impact) {
                this.status = status;
                this.diagnosis = diagnosis;
                this.impact = impact;
            }

            public Builder withStatus(final Status status) {
                if (Objects.equals(this.status, status)) {
                    return this;
                }
                return new Builder(status, this.diagnosis, this.impact);
            }

            public Builder withDiagnosis(final Diagnosis diagnosis) {
                if (Objects.equals(this.diagnosis, diagnosis)) {
                    return this;
                }
                return new Builder(status, diagnosis, impact);
            }

            public Builder withDiagnosis(final UnaryOperator<Diagnosis.Builder> diagnosisConfigurator) {
                return this.withDiagnosis(Diagnosis.builder().transform(diagnosisConfigurator).build());
            }

            public synchronized Builder withImpact(final Impact impact) {
                if (Objects.equals(this.impact, impact)) {
                    return this;
                }
                return new Builder(status, this.diagnosis, impact);
            }

            public Builder withImpact(final UnaryOperator<Impact.Builder> impactConfigurator) {
                return this.withImpact(Impact.builder().transform(impactConfigurator).build());
            }

            public synchronized Analysis build() {
                return new Analysis(this);
            }
        }
    }
}
