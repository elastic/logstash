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

import java.util.function.Predicate;

public final class PortSetting extends IntegerSetting {

    public static final Predicate<Integer> VALID_PORT_RANGE = new Predicate<>() {
        @Override
        public boolean test(Integer integer) {
            return isValid(integer);
        }
    };

    public PortSetting(String name, Integer defaultValue) {
        super(name, defaultValue);
    }

    public PortSetting(String name, Integer defaultValue, boolean strict) {
        this(name, defaultValue, strict, VALID_PORT_RANGE);
    }

    protected PortSetting(String name, Integer defaultValue, boolean strict, Predicate<Integer> validator) {
        super(name, defaultValue, strict, validator);
    }

    public static boolean isValid(int port) {
        return 1 <= port && port <= 65535;
    }

}
