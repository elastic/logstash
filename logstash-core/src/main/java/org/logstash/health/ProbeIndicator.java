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

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

/**
 * A {@code ProbeIndicator} is an {@link Indicator} that has one or more {@link Probe}s attached, and can be used
 * to produce a {@link Report}.
 */
public class ProbeIndicator<OBSERVATION extends ProbeIndicator.Observation> implements Indicator<ProbeIndicator.Report<OBSERVATION>> {
    private static final Logger LOGGER = LogManager.getLogger();

    // Marker Interface
    public interface Observation {}

    @FunctionalInterface
    public interface Observer<OBSERVATION extends Observation> extends Supplier<OBSERVATION> {}

    private final String subject;
    private final Observer<OBSERVATION> observer;

    private final Map<String, Probe<OBSERVATION>> probes = new ConcurrentHashMap<>();

    public ProbeIndicator(final String subject,
                          final Observer<OBSERVATION> observer,
                          final Map<String, Probe<OBSERVATION>> probes) {
        this(subject, observer);
        probes.forEach(this::attachProbe);
    }

    public ProbeIndicator(final String subject,
                          final Observer<OBSERVATION> observer) {
        this.subject = subject;
        this.observer = observer;
    }

    public final void attachProbe(final String name,
                                  final Probe<OBSERVATION> probeToAttach) {
        final Probe<OBSERVATION> existing = probes.putIfAbsent(name, probeToAttach);
        if (Objects.nonNull(existing) && !Objects.equals(existing, probeToAttach)) {
            throw new IllegalArgumentException("Cannot attach probe " + name + " because a different one of the same name is already attached.");
        }
    }

    public final void detachProbe(final String name,
                                  final Probe<OBSERVATION> probeToDetach) {
        Probe<OBSERVATION> remaining = probes.computeIfPresent(name, (key, existing) -> Objects.equals(probeToDetach, existing) ? null : existing);
        if (Objects.nonNull(remaining)) {
            throw new IllegalArgumentException("Cannot detach probe " + name + " because a different one of the same name is attached.");
        }
    }

    public final void detachProbe(final String name) {
        probes.remove(name);
    }

    Probe<OBSERVATION> getProbe(final String name) {
        return probes.get(name);
    }

    @Override
    public Report<OBSERVATION> report(final ReportContext reportContext) {

        LOGGER.debug("report starting with {} probes {}", this.probes.keySet(), reportContext);
        final OBSERVATION observation = observer.get();

        final Status.Holder combinedStatus = new Status.Holder();
        final List<Diagnosis> diagnoses = new ArrayList<>();
        final List<Impact> impacts = new ArrayList<>();
        final Set<ImpactArea> distinctImpactAreas = new HashSet<>();

        for (Map.Entry<String, Probe<OBSERVATION>> probeEntry : this.probes.entrySet()) {
            final String probeName = probeEntry.getKey();
            final Probe.Analysis probeAnalysis = probeEntry.getValue().analyze(observation);
            LOGGER.trace("probe {}: {}", probeName, probeAnalysis);

            if (reportContext.isMuted(probeName)) {
                LOGGER.trace("probe {} is muted", probeName);
            } else {
                combinedStatus.reduce(probeAnalysis.status);
                Optional.ofNullable(probeAnalysis.diagnosis)
                        .ifPresent(diagnoses::add);
                Optional.ofNullable(probeAnalysis.impact)
                        .filter(impacts::add)
                        .map(impact -> impact.impactAreas)
                        .ifPresent(distinctImpactAreas::addAll);
            }
        }

        final Status status = combinedStatus.value();
        final StringBuilder symptomBuilder = new StringBuilder();
        symptomBuilder.append(String.format("The %s is %s", this.subject, status.descriptiveValue()));
        if (distinctImpactAreas.size() + diagnoses.size() > 0) {
            symptomBuilder.append("; ")
                    .append(String.format(distinctImpactAreas.size() == 1 ? "%s area is impacted" : "%s areas are impacted", distinctImpactAreas.size()))
                    .append(" and ")
                    .append(String.format(diagnoses.size() == 1 ? "%s diagnosis is available" : "%s diagnoses are available", diagnoses.size()));
        }
        final String symptom = symptomBuilder.toString();

        return new Report<>(status, observation, symptom, diagnoses, impacts);
    }

    @Override
    public String toString() {
        return "ProbeIndicator{" +
                "observer=" + observer +
                ", probes=" + probes +
                '}';
    }

    @JsonSerialize(using=Report.JsonSerializer.class)
    public static class Report<DETAILS> implements Indicator.Report {
        private final Status status;
        private final DETAILS details;
        private final String symptom;
        private final List<Diagnosis> diagnosis;

        private final List<Impact> impacts;

        public Report(final Status status,
                      final DETAILS details,
                      final String symptom,
                      final List<Diagnosis> diagnosis,
                      final List<Impact> impacts) {
            this.status = status;
            this.details = details;
            this.symptom = symptom;
            this.diagnosis = List.copyOf(diagnosis);
            this.impacts = List.copyOf(impacts);
        }
        public Status status() {
            return status;
        }
        public DETAILS details() {
            return details;
        }
        public String symptom() {
            return symptom;
        }
        public List<Diagnosis> diagnosis() {
            return diagnosis;
        }
        public List<Impact> impacts() {
            return impacts;
        }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Report<?>> {
            @Override
            public void serialize(final Report<?> report,
                                  final JsonGenerator jsonGenerator,
                                  final SerializerProvider serializerProvider) throws IOException {
                jsonGenerator.writeStartObject();

                jsonGenerator.writeObjectField("status", report.status);
                jsonGenerator.writeStringField("symptom", report.symptom);

                if (Objects.nonNull(report.diagnosis) && !report.diagnosis.isEmpty()) {
                    jsonGenerator.writeObjectField("diagnosis", report.diagnosis);
                }

                if (Objects.nonNull(report.impacts) && !report.impacts.isEmpty()) {
                    jsonGenerator.writeObjectField("impacts", report.impacts);
                }

                jsonGenerator.writeObjectField("details", report.details);

                jsonGenerator.writeEndObject();
            }
        }

    }
}
