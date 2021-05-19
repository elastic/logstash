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

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;

/**
 * Static utility methods that provide merge methods for List and Map.
 */
public class Util {
    private Util() {}

    @SuppressWarnings("unchecked")
    public static void mapMerge(final Map<String, Object> target, final Map<String, Object> add) {
        LinkedHashSet<Object> buffer = null;
        for (final Map.Entry<String, Object> entry : add.entrySet()) {
            final String entryKey = entry.getKey();
            final Object entryValue = entry.getValue();
            final Object targetValue = target.get(entryKey);
            if (targetValue == null) {
                target.put(entryKey, entryValue);
            } else {
                if (targetValue instanceof Map && entryValue instanceof Map) {
                    mapMerge((Map<String, Object>) targetValue, (Map<String, Object>) entryValue);
                } else if (entryValue instanceof List) {
                    final List<Object> entryValueList = (List<Object>) entryValue;
                    if (targetValue instanceof List) {
                        if (buffer == null) {
                            buffer = new LinkedHashSet<>();
                        } else {
                            buffer.clear();
                        }
                        mergeLists((List<Object>) targetValue, (List<Object>) entryValue, buffer);
                    } else {
                        final List<Object> targetValueList =
                            new ArrayList<>(entryValueList.size() + 1);
                        targetValueList.add(targetValue);
                        for (final Object o : entryValueList) {
                            if (!targetValue.equals(o)) {
                                targetValueList.add(o);
                            }
                        }
                        target.put(entryKey, targetValueList);
                    }
                } else if (targetValue instanceof List) {
                    final List<Object> targetValueList = (List<Object>) targetValue;
                    if (!targetValueList.contains(entryValue)) {
                        targetValueList.add(entryValue);
                    }
                } else if (!targetValue.equals(entryValue)) {
                    final List<Object> targetValueList = new ArrayList<>(2);
                    targetValueList.add(targetValue);
                    targetValueList.add(entryValue);
                    target.put(entryKey, targetValueList);
                }
            }
        }
    }

    /**
     * Merges elements in the source list into the target list, adding only those in the source
     * list that are not yet contained in the target list while keeping the target list ordered
     * according to last added.
     * @param target Target List
     * @param source Source List
     * @param buffer {@link LinkedHashSet} used as sort buffer
     */
    private static void mergeLists(final List<Object> target, final List<Object> source,
        final LinkedHashSet<Object> buffer) {
        buffer.addAll(target);
        buffer.addAll(source);
        target.clear();
        target.addAll(buffer);
    }
}
