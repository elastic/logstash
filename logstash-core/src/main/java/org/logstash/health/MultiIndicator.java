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
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * A {@code MultiIndicator} is an {@link Indicator} that combines multiple sub-{@link Indicator}s and produces a
 * summarized {@link Report}.
 */
public class MultiIndicator implements Indicator<MultiIndicator.Report> {
    private static final Logger LOGGER = LogManager.getLogger();

    private final Map<String, Indicator<?>> indicators = new ConcurrentHashMap<>();

    public void attachIndicator(final String name,
                                final Indicator<?> indicatorToAttach) {
        final Indicator<?> existing = indicators.putIfAbsent(name, indicatorToAttach);
        if (Objects.nonNull(existing) && !Objects.equals(existing, indicatorToAttach)) {
            throw new IllegalArgumentException(String.format("Cannot attach indicator %s (%s) because a different one of the same name is already attached (%s).", name, indicatorToAttach, existing));
        }
        LOGGER.debug("attached indicator {}=>{} (res:{})", name, indicatorToAttach, this);
    }

    public void detachIndicator(final String name,
                                final Indicator<?> indicatorToDetach) {
        final Indicator<?> remaining = indicators.computeIfPresent(name, (key, existing) -> Objects.isNull(indicatorToDetach) || Objects.equals(indicatorToDetach, existing) ? null : existing);
        if (Objects.nonNull(remaining)) {
            throw new IllegalArgumentException("Cannot detach indicator " + name + " because a different one of the same name is attached.");
        }
        LOGGER.debug("detached indicator {}<={} (res:{})", name, indicatorToDetach, this);
    }

    public <INDICATOR extends Indicator<?>> Optional<INDICATOR> getIndicator(final String name,
                                                                             final Class<INDICATOR> indicatorClass) {
        return getIndicator(name).map(indicatorClass::cast);
    }

    public Optional<Indicator<?>> getIndicator(final String name) {
        return Optional.ofNullable(indicators.get(name));
    }

    @Override
    public Report report(final ReportContext reportContext) {
        LOGGER.debug("report starting with indicators {} for {}", this.indicators, reportContext);
        final Status.Holder combinedStatus = new Status.Holder();

        final Map<String, Indicator.Report> reports = new HashMap<>();
        final Map<Status, Set<String>> indicatorNamesByStatus = new HashMap<>();

        this.indicators.forEach((indicatorName, indicator) -> {
            if (reportContext.isMuted(indicatorName)) {
                LOGGER.trace("sub-indicator {} is muted for {}", indicatorName, reportContext);
            } else {
                reportContext.descend(indicatorName, (scopedContext) -> {
                    final Indicator.Report report = indicator.report(scopedContext);

                    combinedStatus.reduce(report.status());
                    reports.put(indicatorName, report);
                    indicatorNamesByStatus.computeIfAbsent(report.status(), k -> new HashSet<>()).add(indicatorName);
                });
            }
        });

        final StringBuilder symptom = new StringBuilder();
        // to highlight indicators by most-degraded status, we summarize in reverse-order
        final List<String> summaryByStatus = new ArrayList<>(indicatorNamesByStatus.size());
        for (int i = Status.values().length - 1; i >= 0; i--) {
            final Status summarizingStatus = Status.values()[i];
            if (indicatorNamesByStatus.containsKey(summarizingStatus)) {
                final Set<String> indicatorNames = indicatorNamesByStatus.get(summarizingStatus);
                summaryByStatus.add(String.format("%s "+(indicatorNames.size()==1 ? "indicator is" : "indicators are")+" %s (`%s`)",
                        indicatorNames.size(),
                        summarizingStatus.descriptiveValue(),
                        String.join("`, `", indicatorNames)));
            }
        }
        if (summaryByStatus.isEmpty()) {
            symptom.append("no indicators");
        } else if (summaryByStatus.size() == 1) {
            symptom.append(summaryByStatus.get(0));
        } else if (summaryByStatus.size() == 2) {
            symptom.append(summaryByStatus.get(0)).append(" and ").append(summaryByStatus.get(1));
        } else {
            final int lastIndex = summaryByStatus.size() - 1;
            symptom.append(String.join(", ", summaryByStatus.subList(0, lastIndex)))
                    .append(", and ").append(summaryByStatus.get(lastIndex));
        }

        return new Report(combinedStatus.value(), symptom.toString(), reports);
    }

    @Override
    public String toString() {
        return "MultiIndicator{" +
                "indicators=" + indicators +
                '}';
    }

    @JsonSerialize(using=Report.JsonSerializer.class)
    public static class Report implements Indicator.Report {
        private final Status status;
        private final String symptom;
        private final Map<String, Indicator.Report> indicators;

        Report(final Status status,
               final String symptom,
               final Map<String, Indicator.Report> indicators) {
            this.status = status;
            this.symptom = symptom;
            this.indicators = Map.copyOf(indicators);
        }

        @Override
        public Status status() {
            return this.status;
        }

        public String symptom() {
            return this.symptom;
        }

        public Map<String, Indicator.Report> indicators() {
            return this.indicators;
        }

        public static class JsonSerializer extends com.fasterxml.jackson.databind.JsonSerializer<Report> {
            @Override
            public void serialize(final Report report,
                                  final JsonGenerator jsonGenerator,
                                  final SerializerProvider serializerProvider) throws IOException {
                jsonGenerator.writeStartObject();
                jsonGenerator.writeObjectField("status", report.status());
                jsonGenerator.writeStringField("symptom", report.symptom);
                jsonGenerator.writeObjectField("indicators", report.indicators());
                jsonGenerator.writeEndObject();
            }
        }
    }
}
