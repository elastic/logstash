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

import java.util.Collections;
import java.util.List;

public class StringSetting extends BaseSetting<String> {

    private List<String> possibleStrings = Collections.emptyList();

    public StringSetting(String name, String defaultValue, boolean strict, List<String> possibleStrings) {
        super(name, strict, noValidator()); // this super doesn't call validate either if it's strict
        this.possibleStrings = possibleStrings;
        this.defaultValue = defaultValue;

        if (strict) {
            staticValidate(defaultValue, possibleStrings, name);
        }
    }

    public StringSetting(String name, String defaultValue) {
        this(name, defaultValue, true, Collections.emptyList());
    }

    public StringSetting(String name, String defaultValue, boolean strict) {
        this(name, defaultValue, strict, Collections.emptyList());
    }

    @Override
    public void validate(String input) throws IllegalArgumentException {
        if (input == null) {
            throw new IllegalArgumentException(String.format("Setting \"%s\" must be a String. Received:  (NilClass)", this.getName()));
        }
        staticValidate(input, possibleStrings, this.getName());
    }

    private static void staticValidate(String input, List<String> possibleStrings, String name) {
        if (!possibleStrings.isEmpty() && !possibleStrings.contains(input)) {
            throw new IllegalArgumentException(String.format("Invalid value \"%s: %s\" . Options are: %s", name, input, possibleStrings));
        }
    }
}
