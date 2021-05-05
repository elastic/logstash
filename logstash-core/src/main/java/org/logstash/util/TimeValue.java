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
package org.logstash.util;

import org.logstash.RubyUtil;

import java.util.Objects;
import java.util.concurrent.TimeUnit;

/**
 * Express a period of time, expressing in numerical quantity and time unit, for example "3 seconds"
 * */
public class TimeValue {

    public static TimeValue fromValue(Object value) {
        if (value instanceof TimeValue) {
            return (TimeValue) value;
        }
        if (value instanceof String) {
            final String normalized = ((String) value).toLowerCase().trim();
            if (normalized.endsWith("nanos")) {
                return new TimeValue(parse(normalized, 5), TimeUnit.NANOSECONDS);
            }
            if (normalized.endsWith("micros")) {
                return new TimeValue(parse(normalized, 6), TimeUnit.MICROSECONDS);
            }
            if (normalized.endsWith("ms")) {
                return new TimeValue(parse(normalized, 2), TimeUnit.MILLISECONDS);
            }
            if (normalized.endsWith("s")) {
                return new TimeValue(parse(normalized, 1), TimeUnit.SECONDS);
            }
            if (normalized.endsWith("m")) {
                return new TimeValue(parse(normalized, 1), TimeUnit.MINUTES);
            }
            if (normalized.endsWith("h")) {
                return new TimeValue(parse(normalized, 1), TimeUnit.HOURS);
            }
            if (normalized.endsWith("d")) {
                return new TimeValue(parse(normalized, 1), TimeUnit.DAYS);
            }
            if (normalized.matches("^-0*1")) {
                return new TimeValue(-1, TimeUnit.NANOSECONDS);
            }
            throw RubyUtil.RUBY.newArgumentError("invalid time unit: \"" + value + "\"");
        }
        throw RubyUtil.RUBY.newArgumentError("value is not a string: " + value + " [" + value.getClass().getName() + "]");
    }

    private static int parse(String value, int suffix) {
        final String numericPart = value.substring(0, value.length() - suffix).trim();
        try {
            return Integer.parseInt(numericPart);
        } catch (NumberFormatException ex) {
            throw RubyUtil.RUBY.newArgumentError("invalid value for Integer(): \"" + numericPart + "\"");
        }
    }

    private final long duration;
    private final TimeUnit timeUnit;

    /**
     * @param duration number of timeUnit
     * @param timeUnit could be one of nanosecond, microsecond, millisecond, second, minute, hour, day, nanosecond
     * */
    public TimeValue(int duration, String timeUnit) {
        this(duration, TimeUnit.valueOf((timeUnit + "s").toUpperCase()));
    }

    protected TimeValue(long duration, TimeUnit timeUnit) {
        this.duration = duration;
        this.timeUnit = timeUnit;
    }

    public long getDuration() {
        return duration;
    }

    public String getTimeUnit() {
        final String value = timeUnit.toString();
        return value.substring(0, value.length() - 1); // remove last "s"
    }

    public long toNanos() {
        return timeUnit.toNanos(duration);
    }

    public long toSeconds() {
        return timeUnit.toSeconds(duration);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        TimeValue timeValue = (TimeValue) o;
        return (duration == timeValue.duration &&
                timeUnit == timeValue.timeUnit) || (this.toNanos() == timeValue.toNanos());
    }

    @Override
    public int hashCode() {
        return Objects.hash(duration, timeUnit);
    }

    @Override
    public String toString() {
        return "TimeValue{" +
                "duration=" + duration +
                ", timeUnit=" + timeUnit +
                '}';
    }
}
