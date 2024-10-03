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
                this(Status.UNKNOWN, null, null);
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
