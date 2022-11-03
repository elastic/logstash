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


package org.logstash.log;

import org.apache.logging.log4j.message.Message;
import org.apache.logging.log4j.message.MessageFactory2;
import org.apache.logging.log4j.message.ObjectMessage;
import org.apache.logging.log4j.message.ParameterizedMessage;
import org.apache.logging.log4j.message.SimpleMessage;

import java.util.Map;

/**
 * Used in Log4j configuration.
 *
 * Requires Log4j 2.6 and above.
 * */
public final class LogstashMessageFactory implements MessageFactory2 {

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

    @Override
    public Message newMessage(CharSequence charSequence) {
        return new SimpleMessage(charSequence);
    }

    @Override
    public Message newMessage(String message, Object p0) {
        return newMessage(message, new Object[]{p0});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1) {
        return newMessage(message, new Object[]{p0, p1});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2) {
        return newMessage(message, new Object[]{p0, p1, p2});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3) {
        return newMessage(message, new Object[]{p0, p1, p2, p3});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4, Object p5) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4, p5});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4, Object p5, Object p6) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4, p5, p6});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4, Object p5, Object p6, Object p7) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4, p5, p6, p7});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4, Object p5, Object p6, Object p7, Object p8) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4, p5, p6, p7, p8});
    }

    @Override
    public Message newMessage(String message, Object p0, Object p1, Object p2, Object p3, Object p4, Object p5, Object p6, Object p7, Object p8, Object p9) {
        return newMessage(message, new Object[]{p0, p1, p2, p3, p4, p5, p6, p7, p8, p9});
    }
}
