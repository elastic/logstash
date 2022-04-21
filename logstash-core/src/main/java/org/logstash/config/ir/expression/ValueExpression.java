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

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import org.jruby.RubyHash;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;
import org.logstash.secret.SecretVariable;

public class ValueExpression extends Expression {
    protected final Object value;

    public ValueExpression(SourceWithMetadata meta, Object value) throws InvalidIRException {
        super(meta);

        if (!(value == null ||
                value instanceof Short ||
                value instanceof Long ||
                value instanceof Integer ||
                value instanceof Float ||
                value instanceof Double ||
                value instanceof BigDecimal ||
                value instanceof String ||
                value instanceof List ||
                value instanceof RubyHash ||
                value instanceof Instant ||
                value instanceof SecretVariable
        )) {
            // This *should* be caught by the treetop grammar, but we need this case just in case there's a bug
            // somewhere
            throw new InvalidIRException("Invalid eValue " + value + " with class " + value.getClass().getName());
        }

        this.value = value;
    }

    public Object get() {
        return value;
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent sourceComponent) {
        if (sourceComponent == null) return false;
        if (this == sourceComponent) return true;
        if (sourceComponent instanceof ValueExpression) {
            ValueExpression other = (ValueExpression) sourceComponent;
            if (this.get() == null) {
                return (other.get() == null);
            } else {
                return (this.get().equals(other.get()));
            }
        }
        return false;
    }

    @Override
    public String toRubyString() {
        if (value == null) {
            return "null";
        }
        if (value instanceof String) {
            return "'" + get() + "'";
        }

        return get().toString();
    }

    @Override
    public String hashSource() {
        return this.getClass().getCanonicalName() + "|" + value;
    }
}
