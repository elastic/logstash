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
package org.logstash.settings;

import co.elastic.logstash.api.DeprecationLogger;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.RubyUtil;
import org.logstash.log.DefaultDeprecationLogger;
import org.logstash.util.TimeValue;

import java.math.BigInteger;

/**
 * A setting that represents a time value with units (e.g., "18m", "5s", "100ms").
 * Accepts strings with time units or integer values (interpreted as nanoseconds with deprecation warning).
 */
public class TimeValueSetting extends Coercible<TimeValue> {

    private static final Logger LOGGER = LogManager.getLogger();
    private static final DeprecationLogger DEPRECATION_LOGGER = new DefaultDeprecationLogger(LOGGER);

    public TimeValueSetting(String name, String defaultValue) {
        super(name, coerceStatic(name, defaultValue), true, noValidator());
    }

    @Override
    public TimeValue coerce(Object value) {
        return coerceStatic(getName(), value);
    }

    private static TimeValue coerceStatic(String name, Object value) {
        if (value instanceof Integer || value instanceof Long || value instanceof BigInteger) {
            DEPRECATION_LOGGER.deprecated(
                    "Integer value for `" + name + "` does not have a time unit and will be interpreted in nanoseconds. " +
                            "Time units will be required in a future release of Logstash. " +
                            "Acceptable unit suffixes are: `d`, `h`, `m`, `s`, `ms`, `micros`, and `nanos`.");
            return new TimeValue(((Number) value).intValue(), "nanosecond");
        } else if (value instanceof Number) {
            throw RubyUtil.RUBY.newArgumentError(
                    "Non-integer numeric value for `" + name + "` is not supported without a time unit. " +
                            "Please specify a time unit suffix such as `d`, `h`, `m`, `s`, `ms`, `micros`, or `nanos`.");
        }
        return TimeValue.fromValue(value);
    }
}
