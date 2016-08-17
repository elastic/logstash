package org.logstash.log;

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.Marker;
import org.apache.logging.log4j.core.config.Property;
import org.apache.logging.log4j.core.impl.Log4jLogEvent;
import org.apache.logging.log4j.message.Message;

import java.util.List;

@JsonSerialize(using = CustomLogEventSerializer.class)
public class CustomLogEvent extends Log4jLogEvent {
    public CustomLogEvent(final String loggerName, final Marker marker, final String loggerFQCN, final Level level,
                          final Message message, final List<Property> properties, final Throwable t) {
        super(loggerName, marker, loggerFQCN, level, message, properties, t);
    }
}
