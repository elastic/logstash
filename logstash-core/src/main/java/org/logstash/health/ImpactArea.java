package org.logstash.health;

import com.fasterxml.jackson.annotation.JsonValue;

import java.util.Objects;

public enum ImpactArea {
    PIPELINE_EXECUTION,
    ;

    private final String externalValue;

    ImpactArea(final String externalValue) {
        this.externalValue = Objects.requireNonNullElseGet(externalValue, () -> name().toLowerCase());
    }

    ImpactArea() {
        this(null);
    }

    @JsonValue
    public String externalValue() {
        return this.externalValue;
    }
}
