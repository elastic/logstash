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


package org.logstash.log;

import java.util.HashMap;
import java.util.Map;

/**
 * Utility class to save & restore a specified list of System properties
 * */
class SystemPropsSnapshotHelper {

    private final Map<String, String> systemPropertiesDump = new HashMap<>();

    public void takeSnapshot(String... propertyNames) {
        for (String propertyName : propertyNames) {
            dumpSystemProperty(propertyName);
        }
    }

    public void restoreSnapshot(String... propertyNames) {
        for (String propertyName : propertyNames) {
            dumpSystemProperty(propertyName);
        }
    }

    private void dumpSystemProperty(String propertyName) {
        systemPropertiesDump.put(propertyName, System.getProperty(propertyName));
    }

    private void restoreSystemProperty(String propertyName) {
        if (systemPropertiesDump.get(propertyName) == null) {
            System.clearProperty(propertyName);
        } else {
            System.setProperty(propertyName, systemPropertiesDump.get(propertyName));
        }
    }
}
