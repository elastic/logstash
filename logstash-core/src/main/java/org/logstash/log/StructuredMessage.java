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

import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import org.apache.logging.log4j.message.Message;

import java.util.HashMap;
import java.util.Map;

/**
 * Logging message extension class
 * */
@JsonSerialize(using = CustomLogEventSerializer.class)
public class StructuredMessage implements Message {

    private static final long serialVersionUID = 1L;

    private final String message;
    private final transient Map<Object, Object> params;

    @SuppressWarnings({"unchecked","rawtypes"})
    public StructuredMessage(String message) {
        this(message, (Map) null);
    }

    @SuppressWarnings("unchecked")
    public StructuredMessage(String message, Object[] params) {
        final Map<Object, Object> paramsMap;
        if (params.length == 1 && params[0] instanceof Map) {
            paramsMap = (Map) params[0];
        } else {
            paramsMap = new HashMap<>();
            try {
                for (int i = 0; i < params.length; i += 2) {
                    paramsMap.put(params[i].toString(), params[i + 1]);
                }
            } catch (IndexOutOfBoundsException e) {
                throw new IllegalArgumentException("must log key-value pairs");
            }
        }
        this.message = message;
        this.params = paramsMap;
    }

    public StructuredMessage(String message, Map<Object, Object> params) {
        this.message = message;
        this.params = params;
    }

    public String getMessage() {
        return message;
    }

    public Map<Object, Object> getParams() {
        return params;
    }

    @Override
    public Object[] getParameters() {
        return params.values().toArray();
    }

    @Override
    public String getFormattedMessage() {
        String formatted = message;
        if (params != null && !params.isEmpty()) {
            formatted += " " + params;
        }
        return formatted;
    }

    @Override
    public String getFormat() {
        return null;
    }


    @Override
    public Throwable getThrowable() {
        return null;
    }
}
