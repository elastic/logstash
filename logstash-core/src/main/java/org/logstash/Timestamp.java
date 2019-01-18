package org.logstash;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import java.util.Date;
import org.joda.time.Chronology;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.Duration;
import org.joda.time.LocalDateTime;
import org.joda.time.chrono.ISOChronology;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;
import org.logstash.ackedqueue.Queueable;

/**
 * Wrapper around a {@link DateTime} with Logstash specific serialization behaviour.
 * This class is immutable and thread-safe since its only state is held in a final {@link DateTime}
 * reference and {@link DateTime} which itself is immutable and thread-safe.
 */
@JsonSerialize(using = ObjectMappers.TimestampSerializer.class)
@JsonDeserialize(using = ObjectMappers.TimestampDeserializer.class)
public final class Timestamp implements Comparable<Timestamp>, Queueable {

    // all methods setting the time object must set it in the UTC timezone
    private final DateTime time;

    private static final DateTimeFormatter iso8601Formatter = ISODateTimeFormat.dateTime();

    private static final LocalDateTime JAN_1_1970 = new LocalDateTime(1970, 1, 1, 0, 0);

    /**
     * {@link Chronology} for UTC timezone, cached here to avoid lookup of it when constructing
     * {@link DateTime} instances.
     */
    private static final Chronology UTC_CHRONOLOGY = ISOChronology.getInstance(DateTimeZone.UTC);

    public Timestamp() {
        this.time = new DateTime(UTC_CHRONOLOGY);
    }

    public Timestamp(String iso8601) {
        this.time =
            ISODateTimeFormat.dateTimeParser().parseDateTime(iso8601).toDateTime(UTC_CHRONOLOGY);
    }

    public Timestamp(long epoch_milliseconds) {
        this.time = new DateTime(epoch_milliseconds, UTC_CHRONOLOGY);
    }

    public Timestamp(Date date) {
        this.time = new DateTime(date, UTC_CHRONOLOGY);
    }

    public Timestamp(DateTime date) {
        this.time = date.toDateTime(UTC_CHRONOLOGY);
    }

    public DateTime getTime() {
        return time;
    }

    public static Timestamp now() {
        return new Timestamp();
    }

    public String toString() {
        return iso8601Formatter.print(this.time);
    }

    public long usec() {
        // JodaTime only supports milliseconds precision we can only return usec at millisec precision.
        // note that getMillis() return millis since epoch
        return (new Duration(JAN_1_1970.toDateTime(DateTimeZone.UTC), this.time).getMillis()) * 1000;
    }

    @Override
    public int compareTo(Timestamp other) {
        return time.compareTo(other.time);
    }
    
    @Override
    public boolean equals(final Object other) {
        return other instanceof Timestamp && time.equals(((Timestamp) other).time);
    }

    @Override
    public int hashCode() {
        return time.hashCode();
    }

    @Override
    public byte[] serialize() {
        return toString().getBytes();
    }
}
