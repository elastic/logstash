package org.logstash.health;

import java.util.Objects;
import java.util.function.UnaryOperator;

public interface Probe<OBSERVATION extends ProbeIndicator.Observation> {
    Analysis analyze(OBSERVATION observation);

    final class Analysis {
        private final Status status;
        private final Diagnosis diagnosis;
        private final Impact impact;

        Analysis(final Builder builder) {
            this.status = builder.status;
            this.diagnosis = builder.diagnosis;
            this.impact = builder.impact;
        }

        Status status(){
            return status;
        }
        Diagnosis diagnosis() {
            return diagnosis;
        }
        Impact impact() {
            return impact;
        }

        public static Builder builder() {
            return new Builder();
        }

        public static class Builder {
            private Status status = Status.UNKNOWN;
            private Diagnosis diagnosis;
            private Impact impact;

            public synchronized Builder setStatus(final Status status) {
                assert Objects.isNull(this.status) : "status has already been set";
                this.status = status;
                return this;
            }
            public synchronized Builder setDiagnosis(final Diagnosis diagnosis) {
                assert Objects.isNull(this.diagnosis) : "diagnosis has already been set";
                this.diagnosis = diagnosis;
                return this;
            }
            public synchronized Builder setDiagnosis(final UnaryOperator<Diagnosis.Builder> diagnosisConfigurator) {
                return this.setDiagnosis(Diagnosis.builder().configure(diagnosisConfigurator).build());
            }
            public synchronized Builder setImpact(final Impact impact) {
                assert Objects.isNull(this.impact) : "impact has already been set";
                this.impact = impact;
                return this;
            }
            public synchronized Builder setImpact(final UnaryOperator<Impact.Builder> impactConfigurator) {
                return this.setImpact(Impact.builder().configure(impactConfigurator).build());
            }

            public synchronized Analysis build() {
                return new Analysis(this);
            }
        }
    }
}
