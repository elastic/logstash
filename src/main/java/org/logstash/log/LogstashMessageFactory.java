package org.logstash.log;

import org.apache.logging.log4j.message.Message;
import org.apache.logging.log4j.message.MessageFactory;
import org.apache.logging.log4j.message.ObjectMessage;
import org.apache.logging.log4j.message.ParameterizedMessage;
import org.apache.logging.log4j.message.SimpleMessage;

import java.util.Map;

public final class LogstashMessageFactory implements MessageFactory {

    public static final LogstashMessageFactory INSTANCE = new LogstashMessageFactory();

    @Override
    public Message newMessage(Object message) {
        return new ObjectMessage(message);
    }

    @Override
    public Message newMessage(String message) {
        return new SimpleMessage(message);
    }

    @Override
    public Message newMessage(String message, Object... params) {
        if (params.length == 1 && params[0] instanceof Map) {
            return new StructuredMessage(message, params);
        } else {
            return new ParameterizedMessage(message, params);
        }
    }
}
