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
import org.logstash.config.ir.BaseSourceComponent;
import org.logstash.config.ir.HashableWithSource;

/*
 * [foo] == "foostr" eAnd [bar] > 10
 * eAnd(eEq(eventValueExpr("foo"), value("foostr")), eEq(eEventValue("bar"), value(10)))
 *
 * if [foo]
 * notnull(eEventValue("foo"))
 */
public abstract class Expression extends BaseSourceComponent implements HashableWithSource {

    public Expression(SourceWithMetadata meta) {
        super(meta);
    }

    @Override
    public String toString(int indent) {
        return toString();
    }

    @Override
    public String toString() {
        return toRubyString();
    }

    public abstract String toRubyString();

    public String hashSource() {
        return toRubyString();
    }
}
