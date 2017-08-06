package org.logstash;

import java.util.Date;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;
import org.logstash.ackedqueue.Queueable;

/**
 * Wrapper around a {@link DateTime} with Logstash specific serialization behaviour.
 * This class is immutable and thread-safe since its only state is held in a final {@link DateTime}
 * reference and {@link DateTime} which itself is immutable and thread-safe.
 */
public final class Timestamp implements Comparable<Timestamp>, Queueable {

    // all methods setting the time object must set it in the UTC timezone
    private final DateTime time;

    private static final DateTimeFormatter iso8601Formatter = ISODateTimeFormat.dateTime();

    public Timestamp() {
        this.time = new DateTime(DateTimeZone.UTC);
    }

    public Timestamp(String iso8601) {
        this.time = ISODateTimeFormat.dateTimeParser().parseDateTime(iso8601).toDateTime(DateTimeZone.UTC);
    }

    public Timestamp(long epoch_milliseconds) {
        this.time = new DateTime(epoch_milliseconds, DateTimeZone.UTC);
    }

    public Timestamp(Date date) {
        this.time = new DateTime(date, DateTimeZone.UTC);
    }

    public Timestamp(DateTime date) {
        this.time = date.toDateTime(DateTimeZone.UTC);
    }

    public DateTime getTime() {
        return time;
    }

    public static Timestamp now() {
        return new Timestamp();
    }

    public String toString() {
        return iso8601Formatter.print(time);
    }

    public long usec() {
        // JodaTime only supports milliseconds precision we can only return usec at millisec precision.
        // note that getMillis() return millis since epoch
        return time.getMillis() % 1000L * 1000L;
    }

    @Override
    public int compareTo(Timestamp other) {
        return time.compareTo(other.time);
    }

    @Override
    public byte[] serialize() {
        return toString().getBytes();
    }
}
