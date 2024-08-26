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

public interface Setting<T> extends Cloneable {

    String getName();

    T value();

    boolean isSet();

    boolean isStrict();

    void setSafely(T newValue);

    @SuppressWarnings("unchecked")
    default void set(Object newValue) {
        //this could throw a class cast error
        setSafely((T) newValue);
    }

    void reset();

    void validateValue();

    void validate(T input);

    T getDefault();

    void format(List<String> output);
}
