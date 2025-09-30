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

import co.elastic.logstash.api.Password;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;


public class PasswordSetting extends Coercible<Object> {

    private static final Logger LOG = LogManager.getLogger();

    public PasswordSetting(String name, Object defaultValue) {
        this(name, defaultValue, true);
    }

    public PasswordSetting(String name, Object defaultValue, boolean strict) {
        super(name, defaultValue, strict, noValidator());
    }

    @Override
    public Password coerce(Object obj) {
        if (obj instanceof Password) {
            return (Password) obj;
        }
        if (obj != null && !(obj instanceof String)) {
            throw new IllegalArgumentException("Setting `" + getName() + "` could not coerce non-string value to password");
        }
        return new Password((String) obj);
    }

    public Logger getLogger() {
        return LOG;
    }
}
