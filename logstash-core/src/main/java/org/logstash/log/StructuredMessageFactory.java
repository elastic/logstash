package org.logstash.log;

import org.apache.logging.log4j.message.Message;
import org.apache.logging.log4j.message.MessageFactory;
import org.apache.logging.log4j.message.ObjectMessage;
import org.apache.logging.log4j.message.ParameterizedMessage;

import java.util.Collections;
import java.util.Map;

public final class StructuredMessageFactory implements MessageFactory {

    public static final StructuredMessageFactory INSTANCE = new StructuredMessageFactory();

    @Override
    public Message newMessage(Object message) {
        return new ObjectMessage(message);
    }

    @Override
    public Message newMessage(String message) {
        return new StructuredMessage(message);
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
