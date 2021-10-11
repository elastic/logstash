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


package org.logstash;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.temporal.ChronoField;
import java.util.Date;

import org.logstash.ackedqueue.Queueable;

/**
 * Wrapper around a {@link Instant} with Logstash specific serialization behaviour.
 * This class is immutable and thread-safe since its only state is held in a final {@link Instant}
 * reference and {@link Instant} which itself is immutable and thread-safe.
 */
@JsonSerialize(using = ObjectMappers.TimestampSerializer.class)
@JsonDeserialize(using = ObjectMappers.TimestampDeserializer.class)
public final class Timestamp implements Comparable<Timestamp>, Queueable {

    private transient org.joda.time.DateTime time;

    private final Instant instant;

    public Timestamp() {
        this(Clock.systemDefaultZone());
    }

    public Timestamp(String iso8601) {
        this(iso8601, Clock.systemDefaultZone());
    }

    Timestamp(final String iso8601, final Clock clock) {
        this.instant = tryParse(iso8601, clock);
    }

    Timestamp(final Clock clock) {
        this(clock.instant());
    }

    public Timestamp(long epoch_milliseconds) {
        this(Instant.ofEpochMilli(epoch_milliseconds));
    }

    public Timestamp(final Date date) {
        this(date.toInstant());
    }

    public Timestamp(final org.joda.time.DateTime date) {
        this(date.getMillis());
    }

    public Timestamp(final Instant instant) {
        this.instant = instant;
    }

    /**
     * @deprecated This method returns JodaTime which is deprecated in favor of JDK Instant.
     *   * <p> Use {@link Timestamp#toInstant()} instead. </p>
     */
    @Deprecated
    public org.joda.time.DateTime getTime() {
        if (time == null) {
            time = new org.joda.time.DateTime(instant.toEpochMilli(), org.joda.time.DateTimeZone.UTC);
        }
        return time;
    }

    public Instant toInstant() {
        return instant;
    }

    public static Timestamp now() {
        return new Timestamp();
    }

    public String toString() {
        return instant.toString();
    }

    public long toEpochMilli() {
        return instant.toEpochMilli();
    }

    /**
     * @return the fraction of a second as microseconds from 0 to 999,999; not the number of microseconds since epoch
     */
    public long usec() {
        return instant.getNano() / 1000;
    }

    /**
     * @return the fraction of a second as nanoseconds from 0 to 999,999,999; not the number of nanoseconds since epoch
     */
    public long nsec() {
        return instant.getNano();
    }

    @Override
    public int compareTo(Timestamp other) {
        return instant.compareTo(other.instant);
    }
    
    @Override
    public boolean equals(final Object other) {
        return other instanceof Timestamp && instant.equals(((Timestamp) other).instant);
    }

    @Override
    public int hashCode() {
        return instant.hashCode();
    }

    @Override
    public byte[] serialize() {
        return toString().getBytes();
    }

    // Here we build a DateTimeFormatter that is as forgiving as Joda's ISODateTimeFormat.dateTimeParser()
    // Required yyyy-MM-dd date
    // Optional 'T'-prefixed HH:mm:ss.SSS time (defaults to 00:00:00.000)
    // Optional Zone information, in standard or colons-optional formats (defaults to system zone)
    private static final DateTimeFormatter LENIENT_ISO_DATE_TIME_FORMATTER = (new DateTimeFormatterBuilder())
            .parseCaseInsensitive()
            .append(DateTimeFormatter.ISO_LOCAL_DATE)
            // Time is optional, but if present will begin with a T
            .optionalStart().appendLiteral('T').append(DateTimeFormatter.ISO_LOCAL_TIME).optionalEnd()
            // Timezone is optional, and may land in one of a couple different formats.
            .optionalStart().appendZoneOrOffsetId().optionalEnd()
            .optionalStart().appendOffset("+HHmmss", "Z").optionalEnd()
            .parseDefaulting(ChronoField.HOUR_OF_DAY, 0)
            .parseDefaulting(ChronoField.MINUTE_OF_HOUR, 0)
            .parseDefaulting(ChronoField.SECOND_OF_MINUTE, 0)
            .parseDefaulting(ChronoField.NANO_OF_SECOND, 0)
            .toFormatter().withZone(ZoneId.systemDefault());

    private static Instant tryParse(final String iso8601, final Clock clock) {
        try {
            return LENIENT_ISO_DATE_TIME_FORMATTER.withZone(clock.getZone()).parse(iso8601, Instant::from);
        } catch (java.time.format.DateTimeParseException e) {
            throw new IllegalArgumentException(String.format("Invalid ISO8601 input `%s`", iso8601), e);
        }
    }
}
