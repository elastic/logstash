package org.logstash.health;

import com.fasterxml.jackson.annotation.JsonValue;

public enum Status {
    UNKNOWN,
    GREEN,
    YELLOW,
    RED,
    ;

    private final String externalValue = name().toLowerCase();

    @JsonValue
    public String externalValue() {
        return externalValue;
    }

    /**
     * Combine this status with another status.
     * This method is commutative.
     * @param status the other status
     * @return the more-degraded of the two statuses.
     */
    public Status reduce(Status status) {
        if (compareTo(status) >= 0) {
            return this;
        } else {
            return status;
        }
    }
}
