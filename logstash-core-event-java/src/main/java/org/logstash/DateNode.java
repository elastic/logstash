package org.logstash;

import org.joda.time.DateTimeZone;
import org.joda.time.format.DateTimeFormat;
import org.joda.time.format.DateTimeFormatter;

import java.io.IOException;

/**
 * Created by ph on 15-05-22.
 */
public class DateNode implements TemplateNode {
    private DateTimeFormatter formatter;

    public DateNode(String format) {
        this.formatter = DateTimeFormat.forPattern(format).withZone(DateTimeZone.UTC);
    }

    @Override
    public String evaluate(Event event) throws IOException {
        return event.getTimestamp().getTime().toString(this.formatter);
    }
}
