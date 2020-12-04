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

package org.logstash.util;

import co.elastic.logstash.api.Password;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.TreeMap;
import java.util.stream.Collectors;

/**
 * Wrapper of Logstash modules settings, with ability to replace password fields with
 * the obfuscator {@link Password} implementation.
 * */
public final class ModulesSettingArray extends ArrayList<Map<String, Object>> {

    private static final long serialVersionUID = 4094949366274116593L;

    public ModulesSettingArray(Collection<? extends Map<String, Object>> original) {
        super(wrapPasswords(original));
    }

    private static Collection<Map<String, Object>> wrapPasswords(Collection<? extends Map<String, Object>> original) {
        return original.stream()
                .map(ModulesSettingArray::wrapPasswordsInSettings)
                .collect(Collectors.toList());
    }

    private static Map<String, Object> wrapPasswordsInSettings(Map<String, Object> settings) {
        // Insertion order is important. The Map object passed into is usually a org.jruby.RubyHash, which preserves
        // the insertion order, during the scan. Here we need to keep the same order, because tests on modules
        // expects a precise order of keys. It's important to have stable tests.
        final Map<String, Object> acc = new LinkedHashMap<>();
        for (Map.Entry<String, Object> entry : settings.entrySet()) {
            if (entry.getKey().endsWith("password") && !(entry.getValue() instanceof Password)) {
                acc.put(entry.getKey(), new Password((String) entry.getValue()));
            } else {
                acc.put(entry.getKey(), entry.getValue());
            }
        }
        return acc;
    }

    public Map<String, Object> getFirst() {
        try {
            return get(0);
        } catch (IndexOutOfBoundsException ex) {
            return null;
        }
    }

    public Map<String, Object> getLast() {
        try {
            return get(size() - 1);
        } catch (IndexOutOfBoundsException ex) {
            return null;
        }
    }

}
