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


package org.logstash;

import java.util.List;

public class KeyNode {

    private KeyNode() {
        // Utility Class
    }

    // TODO: (colin) this should be moved somewhere else to make it reusable
    //   this is a quick fix to compile on JDK7 a not use String.join that is
    //   only available in JDK8
    public static String join(List<?> list, String delim) {
        int len = list.size();

        if (len == 0) return "";

        final StringBuilder result = new StringBuilder(toString(list.get(0), delim));
        for (int i = 1; i < len; i++) {
            result.append(delim);
            result.append(toString(list.get(i), delim));
        }
        return result.toString();
    }

    private static String toString(Object value, String delim) {
        if (value == null) return "";
        if (value instanceof List) return join((List)value, delim);
        return value.toString();
    }
}
