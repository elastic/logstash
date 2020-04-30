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


package org.logstash.config.ir.expression;

import org.logstash.config.ir.SourceComponent;
import org.logstash.common.SourceWithMetadata;

public class EventValueExpression extends Expression {
    private final String fieldName;

    public EventValueExpression(SourceWithMetadata meta, String fieldName) {
        super(meta);
        this.fieldName = fieldName;
    }

    public String getFieldName() {
        return fieldName;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof EventValueExpression) {
            EventValueExpression other = (EventValueExpression) sourceComponent;
            return (this.getFieldName().equals(other.getFieldName()));
        }
        return false;
    }

    @Override
    public String toString() {
        return "event.get('" + fieldName + "')";
    }

    @Override
    public String toRubyString() {
        return "event.getField('" + fieldName + "')";
    }

    @Override
    public String hashSource() {
        return this.getClass().getCanonicalName() + "|" + fieldName;
    }
}
