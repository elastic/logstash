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

import com.fasterxml.jackson.annotation.JsonValue;

public enum Status {
    GREEN("healthy"),
    UNKNOWN("unknown"),
    YELLOW("concerning"),
    RED("unhealthy"),
    ;

    private final String externalValue = name().toLowerCase();
    private final String descriptiveValue;

    Status(String descriptiveValue) {
        this.descriptiveValue = descriptiveValue;
    }

    @JsonValue
    public String externalValue() {
        return externalValue;
    }

    public String descriptiveValue() { return descriptiveValue; }

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

    public static class Holder {
        private Status status = Status.GREEN;
        public synchronized Status reduce(Status status) {
            return this.status = this.status.reduce(status);
        }
        public synchronized Status value() {
            return this.status;
        }
    }
}
