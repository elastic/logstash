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

import org.jruby.RubyInteger;
import org.jruby.RubyRange;
import org.logstash.RubyUtil;

// Ideally would be a Coercible<Range<Integer>>, but given the fact that
// values can be effectively coerced into the constructor, it needs instances
// of Objects to represent Integer, String, Long to be later coerced into Range<Integer>.
@SuppressWarnings({"rawtypes", "unchecked"})
public class PortRangeSetting extends Coercible<Object> {

    private static final Range<Integer> VALID_PORT_RANGE = new Range<>(1, 65535);
    public static final String PORT_SEPARATOR = "-";

    public PortRangeSetting(String name, Object defaultValue) {
        super(name, defaultValue, true, PortRangeSetting::isValid);
    }

    public static boolean isValid(Object range) {
        if (!(range instanceof Range)) {
            return false;
        }

        return VALID_PORT_RANGE.contains((Range<Integer>) range);
    }

    @Override
    public Range<Integer> coerce(Object obj) {
        if (obj instanceof Range) {
            return (Range) obj;
        }

        if (obj instanceof Integer) {
            Integer val = (Integer) obj;
            return new Range<>(val, val);
        }

        if (obj instanceof Long) {
            Long val = (Long) obj;
            return new Range<>(val.intValue(), val.intValue());
        }

        if (obj instanceof String) {
            String val = ((String) obj).trim();
            String[] parts = val.split(PORT_SEPARATOR);
            String firstStr = parts[0];
            String lastStr;
            if (parts.length == 1) {
                lastStr = firstStr;
            } else {
                lastStr = parts[1];
            }
            try {
                int first = Integer.parseInt(firstStr);
                int last = Integer.parseInt(lastStr);
                return new Range<>(first, last);
            } catch(NumberFormatException e) {
                throw new IllegalArgumentException("Could not coerce [" + obj + "](type: " + obj.getClass() + ") into a port range");
            }
        }

        if (obj instanceof RubyRange) {
            RubyRange rubyRange = (RubyRange) obj;
            RubyInteger begin = rubyRange.begin(RubyUtil.RUBY.getCurrentContext()).convertToInteger();
            RubyInteger end = rubyRange.end(RubyUtil.RUBY.getCurrentContext()).convertToInteger();
            return new Range<>(org.jruby.RubyNumeric.num2int(begin), org.jruby.RubyNumeric.num2int(end));
        }
        throw new IllegalArgumentException("Could not coerce [" + obj + "](type: " + obj.getClass() + ") into a port range");
    }

    @Override
    public void validate(Object value) throws IllegalArgumentException {
        if (!isValid(value)) {
            final String msg = String.format("Invalid value \"%s: %s\", valid options are within the range of %d-%d",
                    getName(), value, VALID_PORT_RANGE.getFirst(), VALID_PORT_RANGE.getLast());

            throw new IllegalArgumentException(msg);
        }
    }
}
