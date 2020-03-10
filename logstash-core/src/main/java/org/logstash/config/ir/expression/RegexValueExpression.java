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

import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.InvalidIRException;
import org.logstash.config.ir.SourceComponent;

public class RegexValueExpression extends ValueExpression {
    private final String regex;

    public RegexValueExpression(SourceWithMetadata meta, Object value) throws InvalidIRException {
        super(meta, value);

        if (!(value instanceof String)) {
            throw new InvalidIRException("Regex value expressions can only take strings!");
        }

        this.regex = getSource();
    }

    @Override
    public Object get() {
        return this.regex;
    }

    public String getSource() {
        return (String) value;
    }

    @Override
    public String toString() {
        return this.value.toString();
    }

    @Override
    public boolean sourceComponentEquals(SourceComponent other) {
        if (other == null) return false;
        if (other instanceof RegexValueExpression) {
            return (((RegexValueExpression) other).getSource().equals(getSource()));
        }
        return false;
    }

    @Override
    public String toRubyString() {
       return (String) value;
    }
}
