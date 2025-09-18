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

import java.util.List;

public class CoercibleStringSetting extends Coercible<Object> {

    private final List<String> possibleStrings;

    @SuppressWarnings("this-escape")
    public CoercibleStringSetting(String name, Object defaultValue, boolean strict, List<String> possibleStrings) {
        // this super doesn't call validate, with strict false it permits to set
        // possibleStrings field used in validate later.
        super(name, defaultValue, false, noValidator());
        this.possibleStrings = possibleStrings;

        if (strict) {
            String coercedDefault = coerce(defaultValue);
            validate(coercedDefault);
            this.defaultValue = coercedDefault;
        } else {
            this.defaultValue = defaultValue;
        }
    }

    @Override
    public String coerce(Object value) {
        if (value == null) {
            return "";
        }
        return value.toString();
    }

    @Override
    public void validate(Object input) throws IllegalArgumentException {
        super.validate(input);

        staticValidate(input.toString(), possibleStrings, this.getName());
    }

    private static void staticValidate(String input, List<String> possibleStrings, String name) {
        if (!possibleStrings.isEmpty() && !possibleStrings.contains(input)) {
            throw new IllegalArgumentException(String.format("Invalid value \"%s\". Options are: %s", input, possibleStrings));
        }
    }


}
