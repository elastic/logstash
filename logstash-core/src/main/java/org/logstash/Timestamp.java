package org.logstash;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import java.util.Date;
import org.joda.time.DateTime;
import org.joda.time.DateTimeZone;
import org.joda.time.Duration;
import org.joda.time.LocalDateTime;
import org.joda.time.format.DateTimeFormatter;
import org.joda.time.format.ISODateTimeFormat;
import org.logstash.ackedqueue.Queueable;
import org.logstash.json.TimestampSerializer;

@JsonSerialize(using = TimestampSerializer.class)
public final class Timestamp implements Cloneable, Comparable<Timestamp>, Queueable {

    // all methods setting the time object must set it in the UTC timezone
    private DateTime time;

    private static final DateTimeFormatter iso8601Formatter = ISODateTimeFormat.dateTime();

    private static final LocalDateTime JAN_1_1970 = new LocalDateTime(1970, 1, 1, 0, 0);

    public Timestamp() {
        this.time = new DateTime(DateTimeZone.UTC);
    }

    public Timestamp(String iso8601) {
        this.time = ISODateTimeFormat.dateTimeParser().parseDateTime(iso8601).toDateTime(DateTimeZone.UTC);
    }

    public Timestamp(Timestamp t) {
        this.time = t.getTime();
    }

    public Timestamp(long epoch_milliseconds) {
        this.time = new DateTime(epoch_milliseconds, DateTimeZone.UTC);
    }

    public Timestamp(Long epoch_milliseconds) {
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

    public void setTime(DateTime time) {
        this.time = time.toDateTime(DateTimeZone.UTC);
    }

    public static Timestamp now() {
        return new Timestamp();
    }

    public String toIso8601() {
        return iso8601Formatter.print(this.time);
    }

    public String toString() {
        return toIso8601();
    }

    public long usec() {
        // JodaTime only supports milliseconds precision we can only return usec at millisec precision.
        // note that getMillis() return millis since epoch
        return (new Duration(JAN_1_1970.toDateTime(DateTimeZone.UTC), this.time).getMillis() % 1000) * 1000;
    }

    @Override
    public int compareTo(Timestamp other) {
        return getTime().compareTo(other.getTime());
    }

    @Override
    public Timestamp clone() throws CloneNotSupportedException {
        Timestamp clone = (Timestamp)super.clone();
        clone.setTime(this.getTime());
        return clone;
    }

    @Override
    public byte[] serialize() {
        return toString().getBytes();
    }
}
